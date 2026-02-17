/**
 * Cloud Functions dla BC Agencja.
 * - searchNip: proxy do API WL (wl-api.mf.gov.pl) – unika CORS na web.
 * - getDocumentWithWatermark: pobranie PDF z VDR z dynamicznym znakiem wodnym (kto, data, IP).
 */

import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
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
function setCorsHeaders(res: { setHeader: (name: string, value: string) => void }, allowAuth = false) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", allowAuth ? "Content-Type, Authorization" : "Content-Type");
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
export const getDocumentWithWatermark = onRequest(
  { cors: false, region: "europe-west1", maxInstances: 20 },
  async (req, res) => {
    setCorsHeaders(res, true);
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
