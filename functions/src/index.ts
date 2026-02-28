/**
 * Cloud Functions dla BC Agencja.
 * - searchNip: proxy do API WL (wl-api.mf.gov.pl) – unika CORS na web.
 * - getDocumentWithWatermark: pobranie PDF z VDR z dynamicznym znakiem wodnym (kto, data, IP).
 * - linkedinExchangeCode: wymiana kodu OAuth LinkedIn (OpenID Connect) na Firebase custom token.
 *
 * Zmienne środowiskowe (LinkedIn, Gmail itd.): ustaw w Google Cloud Console dla produkcji
 * lub w pliku functions/.env / functions/config.env przy lokalnym uruchomieniu (emulator).
 */

// W Cloud Run (produkcja) zmienne ustawia gcloud/Console – nie ładuj pliku (unika problemów ze startem).
if (!process.env.K_SERVICE) {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const path = require("path");
  const fs = require("fs");
  const loadEnv = require("dotenv").config;
  const possiblePaths = [
    path.join(process.cwd(), "functions", "config.env"),
    path.join(process.cwd(), "functions", ".env"),
    path.join(process.cwd(), "config.env"),
    path.join(process.cwd(), ".env"),
    path.join(__dirname, "..", "config.env"),
    path.join(__dirname, "..", ".env"),
  ];
  for (const p of possiblePaths) {
    if (fs.existsSync(p)) {
      loadEnv({ path: p });
      break;
    }
  }
}

import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import nodemailer from "nodemailer";
import { PDFDocument, StandardFonts, rgb } from "pdf-lib";

const WL_API_BASE = "https://wl-api.mf.gov.pl";

if (!admin.apps.length) {
  admin.initializeApp();
}

const auth = admin.auth();
const firestore = admin.firestore();
const bucket = admin.storage().bucket();

setGlobalOptions({ maxInstances: 10 });

/** Ustawia nagłówki CORS – wymagane dla requestów z przeglądarki (localhost, produkcja). */
function setCorsHeaders(
  res: { setHeader: (name: string, value: string) => void },
  options: { allowAuth?: boolean; allowPost?: boolean } = {}
) {
  const { allowAuth = false, allowPost = false } = options;
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader(
    "Access-Control-Allow-Methods",
    allowPost ? "GET, POST, OPTIONS" : "GET, OPTIONS"
  );
  res.setHeader(
    "Access-Control-Allow-Headers",
    allowAuth ? "Content-Type, Authorization" : "Content-Type"
  );
}

/** Proxy do API WL – wyszukiwanie podmiotu po NIP. Unika CORS na Flutter Web. */
export const searchNip = onRequest(
  { cors: false, region: "europe-west1" },
  async (req, res) => {
    setCorsHeaders(res);
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    const nip = req.query.nip as string | undefined;
    const date = (req.query.date as string) || new Date().toISOString().slice(0, 10);
    const normalizedNip = nip ? nip.replace(/\D/g, "") : "";

    if (normalizedNip.length !== 10) {
      res.status(400).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "NIP musi mieć 10 cyfr" }));
      return;
    }

    const url = `${WL_API_BASE}/api/search/nip/${normalizedNip}?date=${date}`;

    try {
      const response = await fetch(url);
      const body = await response.text();
      res.status(response.status).setHeader("Content-Type", "application/json").send(body);
    } catch (e) {
      logger.error("searchNip proxy error", e);
      res.status(502).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "Błąd połączenia z rejestrem" }));
    }
  }
);

/** Pobiera IP klienta z nagłówków (za proxy / load balancerem). */
function getClientIp(req: { headers: Record<string, string | string[] | undefined> }): string {
  const forwarded = req.headers["x-forwarded-for"];
  const first = Array.isArray(forwarded) ? forwarded[0] : forwarded;
  const ip = (typeof first === "string" ? first.split(",")[0]?.trim() : undefined) || undefined;
  const appEngineIp = req.headers["x-appengine-user-ip"];
  const direct = Array.isArray(appEngineIp) ? appEngineIp[0] : appEngineIp;
  return (ip || direct || "").toString() || "unknown";
}

/** Format daty dla watermarka: DD.MM.RRRR */
function formatWatermarkDate(d: Date): string {
  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const year = d.getFullYear();
  return `${day}.${month}.${year}`;
}

/**
 * Pobranie dokumentu VDR z dynamicznym znakiem wodnym.
 * GET ?listingId=...&documentPath=... (documentPath = ścieżka w Storage, np. listings/xyz/vdr/umowa.pdf)
 * Nagłówek: Authorization: Bearer <Firebase ID Token>
 * Zwraca: PDF z tekstem "Dla: {displayName}, {data}, IP: {ip}" na każdej stronie + log w document_downloads.
 */
/** Walidacja adresu e-mail (prosty regex). */
function isValidEmail(email: string): boolean {
  return /^[\w\-+.]+@[\w\-]+(\.[\w\-]+)+$/.test(email);
}

/**
 * Wysyła kalkulację ROI na podany adres e-mail.
 * POST, body JSON: { email: string, subject: string, body: string }.
 * Wymaga ustawienia w konfiguracji Firebase (lub .env): GMAIL_USER, GMAIL_APP_PASSWORD.
 * Gdy SMTP nie jest skonfigurowany, zwraca 503.
 */
export const sendRoiCalculationEmail = onRequest(
  { cors: false, region: "europe-west1", maxInstances: 10 },
  async (req, res) => {
    setCorsHeaders(res, { allowPost: true });
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "Metoda dozwolona: POST" })
      );
      return;
    }

    let payload: { email?: string; subject?: string; body?: string };
    try {
      payload = typeof req.body === "string" ? JSON.parse(req.body) : req.body ?? {};
    } catch {
      res.status(400).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "Nieprawidłowy JSON w body" })
      );
      return;
    }

    const email = typeof payload.email === "string" ? payload.email.trim() : "";
    const subject = typeof payload.subject === "string" ? payload.subject : "Kalkulacja ROI – BC Agencja";
    const body = typeof payload.body === "string" ? payload.body : "";

    if (!email || !isValidEmail(email)) {
      res.status(400).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "Nieprawidłowy lub pusty adres e-mail" })
      );
      return;
    }

    const gmailUser = process.env.GMAIL_USER;
    const gmailPass = process.env.GMAIL_APP_PASSWORD;
    if (!gmailUser || !gmailPass) {
      logger.warn("sendRoiCalculationEmail: GMAIL_USER / GMAIL_APP_PASSWORD nie ustawione");
      res.status(503).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "Wysyłka e-mail nie jest skonfigurowana" })
      );
      return;
    }

    const transporter = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 587,
      secure: false,
      auth: { user: gmailUser, pass: gmailPass },
    });

    try {
      await transporter.sendMail({
        from: `"BC Agencja" <${gmailUser}>`,
        to: email,
        subject: subject || "Kalkulacja ROI – BC Agencja",
        text: body,
      });
      res.status(200).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ ok: true })
      );
    } catch (e) {
      logger.error("sendRoiCalculationEmail: błąd wysyłki", e);
      res.status(500).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "Błąd wysyłania e-mail" })
      );
    }
  }
);

/**
 * LinkedIn OAuth (OpenID Connect) – wymiana kodu na tokeny i utworzenie Firebase custom token.
 * Wymaga zmiennych środowiskowych (Primary Client Secret z LinkedIn Developer Portal):
 *   - LINKEDIN_CLIENT_ID
 *   - LINKEDIN_CLIENT_SECRET
 * Ustawienie: Firebase Console → Functions → linkedinExchangeCode → Environment variables
 * lub w pliku .env (lokalnie) / Google Secret Manager (produkcja).
 */
const LINKEDIN_TOKEN_URL = "https://www.linkedin.com/oauth/v2/accessToken";
const LINKEDIN_USERINFO_URL = "https://api.linkedin.com/v2/userinfo";

interface LinkedInTokenResponse {
  access_token?: string;
  id_token?: string;
  expires_in?: number;
  scope?: string;
}

interface LinkedInUserInfo {
  sub?: string;
  name?: string;
  given_name?: string;
  family_name?: string;
  picture?: string;
  email?: string;
  email_verified?: boolean;
  locale?: string;
}

export const linkedinExchangeCode = onRequest(
  { cors: false, region: "europe-west1" },
  async (req, res) => {
    setCorsHeaders(res, { allowPost: true, allowAuth: false });
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "Metoda dozwolona: POST" })
      );
      return;
    }

    const clientId = process.env.LINKEDIN_CLIENT_ID;
    const clientSecret = process.env.LINKEDIN_CLIENT_SECRET;
    if (!clientId || !clientSecret) {
      logger.warn("linkedinExchangeCode: LINKEDIN_CLIENT_ID / LINKEDIN_CLIENT_SECRET nie ustawione");
      res.status(503).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "LinkedIn OAuth nie skonfigurowany" })
      );
      return;
    }

    let body: { code?: string; redirect_uri?: string };
    try {
      body = typeof req.body === "string" ? JSON.parse(req.body) : req.body ?? {};
    } catch {
      res.status(400).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "Nieprawidłowy JSON w body" })
      );
      return;
    }

    const code = typeof body.code === "string" ? body.code.trim() : "";
    const redirectUri = typeof body.redirect_uri === "string" ? body.redirect_uri.trim() : "";
    if (!code || !redirectUri) {
      res.status(400).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "Wymagane pola: code, redirect_uri" })
      );
      return;
    }

    const tokenParams = new URLSearchParams({
      grant_type: "authorization_code",
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
    });

    let tokenRes: Response;
    try {
      tokenRes = await fetch(LINKEDIN_TOKEN_URL, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: tokenParams.toString(),
      });
    } catch (e) {
      logger.error("linkedinExchangeCode: błąd połączenia z LinkedIn", e);
      res.status(502).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "Błąd połączenia z LinkedIn" })
      );
      return;
    }

    const tokenData = (await tokenRes.json()) as LinkedInTokenResponse & { error?: string };
    if (!tokenRes.ok || tokenData.error) {
      logger.warn("linkedinExchangeCode: LinkedIn token error", { status: tokenRes.status, tokenData });
      res.status(400).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: tokenData.error ?? "Błąd autoryzacji LinkedIn" })
      );
      return;
    }

    const accessToken = tokenData.access_token;
    let email: string | undefined;
    let displayName: string | undefined;
    let photoUrl: string | undefined;
    if (tokenData.id_token) {
      try {
        const parts = (tokenData.id_token as string).split(".");
        if (parts.length === 3) {
          const payload = JSON.parse(
            Buffer.from(parts[1], "base64url").toString("utf8")
          ) as Record<string, unknown>;
          if (!email) email = payload.email as string | undefined;
          if (!displayName) displayName = payload.name as string | undefined;
          if (!photoUrl) photoUrl = payload.picture as string | undefined;
        }
      } catch {
        // ignore
      }
    }

    if (!email && accessToken) {
      try {
        const userRes = await fetch(LINKEDIN_USERINFO_URL, {
          headers: { Authorization: `Bearer ${accessToken}` },
        });
        if (userRes.ok) {
          const userInfo = (await userRes.json()) as LinkedInUserInfo;
          email = userInfo.email ?? email;
          displayName = displayName ?? userInfo.name;
          photoUrl = userInfo.picture;
        }
      } catch (e) {
        logger.warn("linkedinExchangeCode: userinfo failed", e);
      }
    }

    if (!email) {
      res.status(400).setHeader("Content-Type", "application/json").send(
        JSON.stringify({ error: "LinkedIn nie zwrócił adresu e-mail (wymagany zakres email)" })
      );
      return;
    }

    let uid: string;
    try {
      const existing = await auth.getUserByEmail(email);
      uid = existing.uid;
      if (displayName || photoUrl) {
        await auth.updateUser(uid, {
          ...(displayName && { displayName }),
          ...(photoUrl && { photoURL: photoUrl }),
        });
      }
    } catch {
      const newUser = await auth.createUser({
        email,
        displayName: displayName ?? email,
        photoURL: photoUrl,
        emailVerified: true,
      });
      uid = newUser.uid;
    }

    const customToken = await auth.createCustomToken(uid);
    res.status(200).setHeader("Content-Type", "application/json").send(
      JSON.stringify({ customToken })
    );
  }
);

export const getDocumentWithWatermark = onRequest(
  { cors: false, region: "europe-west1", maxInstances: 20 },
  async (req, res) => {
    setCorsHeaders(res, { allowAuth: true });
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "GET") {
      res.status(405).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "Metoda dozwolona: GET" }));
      return;
    }

    const listingId = req.query.listingId as string | undefined;
    const documentPath = req.query.documentPath as string | undefined;
    const authHeader = req.headers.authorization;

    if (!listingId?.trim() || !documentPath?.trim()) {
      res.status(400).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "Wymagane parametry: listingId, documentPath" }));
      return;
    }
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "Brak tokena autoryzacji (Bearer)" }));
      return;
    }

    const token = authHeader.slice(7);
    let decoded: admin.auth.DecodedIdToken;
    try {
      decoded = await auth.verifyIdToken(token);
    } catch (e) {
      logger.warn("getDocumentWithWatermark: invalid token", e);
      res.status(401).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "Nieprawidłowy lub wygasły token" }));
      return;
    }

    const uid = decoded.uid;
    if (documentPath.includes("..") || !documentPath.startsWith("listings/")) {
      res.status(400).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "Nieprawidłowa ścieżka dokumentu" }));
      return;
    }
    if (!documentPath.includes(listingId)) {
      res.status(400).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "documentPath musi dotyczyć podanego listingId" }));
      return;
    }

    const userDoc = await firestore.collection("users").doc(uid).get();
    const userData = userDoc.data();
    const vdrList = userData?.vdrAccessForListingIds as string[] | undefined;
    const hasVdr = Array.isArray(vdrList) && vdrList.includes(listingId);
    if (!hasVdr) {
      res.status(403).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "Brak dostępu VDR do tej oferty" }));
      return;
    }

    const displayName = (userData?.displayName as string) || userData?.email as string || "Użytkownik";
    const ip = getClientIp(req);
    const now = new Date();
    const watermarkText = `Dla: ${displayName}, ${formatWatermarkDate(now)}, IP: ${ip}`;

    const file = bucket.file(documentPath);
    let pdfBytes: Buffer;
    try {
      const [buf] = await file.download();
      pdfBytes = Buffer.from(buf);
    } catch (e) {
      logger.error("getDocumentWithWatermark: storage download failed", { documentPath, e });
      res.status(404).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "Nie znaleziono dokumentu w Storage" }));
      return;
    }

    try {
      const pdfDoc = await PDFDocument.load(pdfBytes);
      const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
      const pages = pdfDoc.getPages();
      const fontSize = 10;
      const color = rgb(0.4, 0.4, 0.4);

      for (const page of pages) {
        const { width } = page.getSize();
        page.drawText(watermarkText, {
          x: 24,
          y: 24,
          size: fontSize,
          font,
          color,
        });
        page.drawText(watermarkText, {
          x: width - 24 - font.widthOfTextAtSize(watermarkText, fontSize),
          y: 24,
          size: fontSize,
          font,
          color,
        });
      }

      const watermarkedPdfBytes = await pdfDoc.save();
      const documentId = documentPath.split("/").pop() ?? documentPath;

      await firestore.collection("document_downloads").add({
        userId: uid,
        listingId,
        documentId,
        documentPath,
        ipAddress: ip,
        displayName,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      const filename = documentId.endsWith(".pdf") ? documentId : `${documentId}.pdf`;
      res.setHeader("Content-Type", "application/pdf");
      res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
      res.status(200).send(Buffer.from(watermarkedPdfBytes));
    } catch (e) {
      logger.error("getDocumentWithWatermark: pdf-lib or send failed", e);
      res.status(500).setHeader("Content-Type", "application/json")
        .send(JSON.stringify({ error: "Błąd nakładania znaku wodnego" }));
    }
  }
);
