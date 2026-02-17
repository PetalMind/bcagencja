# CORS dla Firebase Storage (web / localhost)

Na **web** przeglądarka blokuje ładowanie obrazów z Firebase Storage z innej domeny (np. `https://firebasestorage.googleapis.com`) gdy aplikacja działa na `http://localhost:XXXX` – brak nagłówka `Access-Control-Allow-Origin`.

## Rozwiązanie

Należy ustawić CORS na bucketcie Cloud Storage (Firebase Storage).

### 1. Plik konfiguracyjny

W repozytorium jest plik **`storage.cors.json`** z dozwolonymi originami (localhost i typowe porty).  
Jeśli używasz innego portu (np. 8081), dopisz go do tablicy `"origin"`:

```json
"origin": [
  "http://localhost",
  "http://localhost:50374",
  "http://localhost:8080",
  "http://localhost:3000",
  "http://localhost:5000",
  "http://localhost:8081",
  "http://127.0.0.1",
  ...
]
```

Dla **produkcji** dopisz domenę, np. `"https://twoja-domena.pl"`.

### 2. Zastosowanie konfiguracji (gsutil)

Potrzebujesz **Google Cloud SDK** z `gsutil` (np. `gcloud` + `gsutil`).

1. Zaloguj się i ustaw projekt:
   ```bash
   gcloud auth login
   gcloud config set project bc-agencja
   ```

2. Zastosuj CORS na bucketcie Storage:
   ```bash
   gsutil cors set storage.cors.json gs://bc-agencja.firebasestorage.app
   ```
   Jeśli Twój bucket ma nazwę `bc-agencja.appspot.com`, użyj:
   ```bash
   gsutil cors set storage.cors.json gs://bc-agencja.appspot.com
   ```

3. Sprawdź nazwę bucketa w **Firebase Console** → Storage → zakładka „Files” (u góry widać nazwę bucketa).

### 3. Weryfikacja

```bash
gsutil cors get gs://bc-agencja.firebasestorage.app
```

Po zastosowaniu CORS odśwież aplikację na localhost – miniatury zdjęć w kroku „Dok.” (Dokumentacja) powinny się ładować bez błędu CORS.
