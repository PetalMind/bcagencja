# Skrypty dla Cloud Functions

## Ustawienie zmiennych z config.env w Google Cloud

Zmienne z pliku `functions/config.env` (LINKEDIN_CLIENT_ID, LINKEDIN_CLIENT_SECRET) możesz przenieść do Google Cloud na dwa sposoby.

### 1. Skrypt (gcloud CLI)

**Wymagania:** Zainstalowane [gcloud CLI](https://cloud.google.com/sdk/docs/install), zalogowanie (`gcloud auth login`), projekt `bc-agencja` ustawiony.

1. Wdróż najpierw funkcje (jeśli jeszcze nie): z katalogu projektu  
   `firebase deploy --only functions`
2. Uruchom skrypt z katalogu **projektu** (bcagencja) lub z **functions/**:
   - z projektu: `node functions/scripts/set-env-from-config.js`
   - z functions: `npm run set-env`

Skrypt odczyta `config.env` i ustawi zmienne dla usługi Cloud Run odpowiadającej funkcji `linkedinExchangeCode`.

### 2. Ręcznie w Google Cloud Console

1. Otwórz [Cloud Run](https://console.cloud.google.com/run?project=bc-agencja).
2. Znajdź usługę **linkedinexchangecode** (region europe-west1).
3. Kliknij nazwę → **Edit** → zakładka **Variables & secrets**.
4. W sekcji **Environment variables** dodaj:
   - `LINKEDIN_CLIENT_ID` = wartość z config.env
   - `LINKEDIN_CLIENT_SECRET` = wartość z config.env
5. **Deploy**.

Zmienne z config.env (LINKEDIN_*, ewentualnie GMAIL_* itd.) ustaw dokładnie tak samo w Console.
