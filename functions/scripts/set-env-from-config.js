#!/usr/bin/env node
/**
 * Ustawia zmienne środowiskowe Cloud Function linkedinExchangeCode w Google Cloud
 * na podstawie pliku functions/config.env.
 *
 * Wymaga: gcloud CLI, zalogowanie (gcloud auth login), projekt ustawiony (gcloud config set project bc-agencja).
 *
 * Użycie z katalogu projektu:
 *   node functions/scripts/set-env-from-config.js
 * lub z katalogu functions:
 *   node scripts/set-env-from-config.js
 */

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const PROJECT_ID = "bc-agencja";
const REGION = "europe-west1";
const FUNCTION_NAME = "linkedinExchangeCode";

// Ścieżka do config.env (skrypt z repo root: node functions/scripts/... lub z functions: node scripts/...)
const possibleEnvPaths = [
  path.join(process.cwd(), "functions", "config.env"),
  path.join(process.cwd(), "config.env"),
  path.join(__dirname, "..", "config.env"),
  path.join(__dirname, "..", ".env"),
];

let envPath = null;
for (const p of possibleEnvPaths) {
  if (fs.existsSync(p)) {
    envPath = p;
    break;
  }
}

if (!envPath) {
  console.error("Nie znaleziono config.env ani .env. Sprawdzone ścieżki:");
  possibleEnvPaths.forEach((p) => console.error("  ", p));
  process.exit(1);
}

const content = fs.readFileSync(envPath, "utf8");
const vars = {};
for (const line of content.split(/\r?\n/)) {
  const trimmed = line.trim().replace(/^\uFEFF/, ""); // bez BOM
  if (!trimmed || trimmed.startsWith("#")) continue;
  const eq = trimmed.indexOf("=");
  if (eq <= 0) continue;
  const key = trimmed.slice(0, eq).trim();
  let value = trimmed.slice(eq + 1).trim();
  if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
    value = value.slice(1, -1);
  }
  vars[key] = value;
}

const wanted = ["LINKEDIN_CLIENT_ID", "LINKEDIN_CLIENT_SECRET"];
const missing = wanted.filter((k) => !vars[k]);
if (missing.length) {
  console.error("Brak w config.env:", missing.join(", "));
  console.error("Odczytany plik:", envPath);
  console.error("Znalezione klucze:", Object.keys(vars).join(", ") || "(brak)");
  process.exit(1);
}

// Cloud Run service name dla Firebase Function v2 (zazwyczaj nazwa funkcji w lowercase)
const serviceName = FUNCTION_NAME.replace(/([A-Z])/g, (m) => m.toLowerCase());

console.log("Ustawianie zmiennych dla Cloud Run service:", serviceName, "w", REGION);

// Wartości w pojedynczych cudzysłowach (bezpieczne dla = i spacji)
const arg = wanted.map((k) => `${k}='${String(vars[k]).replace(/'/g, "'\"'\"'")}'`).join(",");

// --update-env-vars tylko DODAJE/aktualizuje te zmienne, nie nadpisuje innych (PORT itd.)
try {
  execSync(
    `gcloud run services update ${serviceName} --region=${REGION} --project=${PROJECT_ID} --update-env-vars=${arg}`,
    { stdio: "inherit", shell: true }
  );
  console.log("Zmienne ustawione.");
} catch (e) {
  if (e.message && e.message.includes("NOT_FOUND")) {
    console.error("\nSerwis Cloud Run nie znaleziony. Najpierw wdróż funkcje:");
    console.error("  firebase deploy --only functions");
    console.error("Potem sprawdź nazwę usługi w:");
    console.error("  https://console.cloud.google.com/run?project=" + PROJECT_ID);
    console.error("Albo ustaw zmienne ręcznie: Cloud Run → wybierz usługę → Edit → Variables & secrets.");
  }
  process.exit(1);
}
