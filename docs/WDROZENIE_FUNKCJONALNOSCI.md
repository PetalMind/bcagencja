# Plan wdrożenia funkcjonalności transakcyjnych – BCA Agencja

**Wersja:** 1.0  
**Data:** 16.02.2026  
**Kontekst:** Przekształcenie strony wizerunkowej w narzędzie transakcyjne z progresywnym dostępem do ofert, automatyzacją leadów i zabezpieczeniem dokumentacji.

---

## 1. Stan obecny (krótka analiza)

| Obszar | Stan | Uwagi |
|--------|------|--------|
| **Frontend** | Flutter (web, iOS, macOS) | Riverpod, go_router, brak Firebase SDK w aplikacji |
| **Backend** | Firebase (Hosting, Firestore, Cloud Functions) | Functions prawie puste, Firestore z tymczasowymi regułami |
| **Auth** | Brak | Brak logowania, ról, NDA |
| **Oferty** | Model `Property` + mocki | Brak poziomów dostępu, brak VDR, brak watermarkingu |
| **Formularz oferty** | Add Listing – 6 kroków | Jednolity dla wszystkich typów, brak wymaganych PDF-ów |
| **Strona główna** | Hero + listy + statystyki | Brak wyraźnych kafli „Inwestor” / „Sprzedaj” |

---

## 2. Model progresywnego dostępu (lejek walidacji)

### 2.1 Poziomy dostępu

| Poziom | Nazwa | Warunek odblokowania | Co użytkownik widzi |
|--------|--------|----------------------|----------------------|
| **1 – Publiczny** | Teaser | Brak (anonim) | Ogólne info, typ, powierzchnia, przedział ceny, 1 zdjęcie reprezentatywne. **Bez adresu**, bez galerii. |
| **2 – Identity Verified** | Pełna oferta | Logowanie (LinkedIn lub NIP) + akceptacja NDA | Dokładna lokalizacja, pełna galeria, parametry, kontakt do agenta. |
| **3 – VDR (Capital Verified)** | Virtual Data Room | Wgranie Proof of Funds (promesa/wyciąg) + akceptacja przez Dyrektora | Operaty, umowy najmu, audyty – **z dynamicznym znakiem wodnym** przy pobieraniu. |

### 2.2 Implementacja poziomów w danych

- **Firestore:** każda oferta ma pola `accessLevel` (1–3) oraz listy plików z podziałem na: `teaserAssets`, `level2Assets`, `vdrDocuments`.
- **API/Frontend:** zwracanie wariantu oferty (teaser / full / vdr) w zależności od `user.accessLevel` i ewentualnie `user.vdrAccessForListingIds`.

---

## 3. Moduł dostępu (progresywna walidacja)

### 3.1 Grant Level 2 (Identity Verified)

| Element | Sposób wdrożenia |
|---------|-------------------|
| **Logowanie** | **LinkedIn OAuth 2.0** – wygodne dla inwestorów. Alternatywa: **weryfikacja NIP** (API, np. rejestr.io / GUS / inny rejestr przedsiębiorców). |
| **NDA** | Checkbox „Akceptuję regulamin i NDA” + zapis w Firestore: `ndaAcceptedAt`, `ndaAcceptedIp`, `userId`. Można dodać osobny dokument `nda_acceptances/{id}`. |
| **Akcja** | Po weryfikacji tożsamości: automatyczne dodanie użytkownika do kolekcji **Leads** (lub pole `role: lead` w `users`). |

**Paczki / usługi:**

- **Flutter:** `firebase_auth` + Custom Auth (Cloud Function przyjmuje token z LinkedIn lub dane NIP i tworzy/aktualizuje użytkownika).
- **LinkedIn:** OAuth 2.0 przez Cloud Function (redirect URL, wymiana kodu na token, odczyt podstawowych danych profilu).
- **NIP:** Cloud Function wywołująca zewnętrzne API (np. rejestr.io), weryfikacja firmy, zapis `companyName`, `nip` w profilu użytkownika.

### 3.2 Grant Level 3 (VDR – Capital Verified)

| Element | Sposób wdrożenia |
|---------|-------------------|
| **Upload dokumentu** | Formularz: wybór oferty + upload **PDF** (Promesa / wyciąg). Plik do Cloud Storage (np. `proof_of_funds/{userId}/{listingId}/{timestamp}.pdf`) + wpis w Firestore `vdr_requests`. |
| **Ręczna weryfikacja** | W panelu Admin/Dyrektor: przycisk „Przyznaj dostęp VDR” dla użytkownika bez uploadu (relacja off-line). |
| **Powiadomienie** | Cloud Function (Firestore trigger na nowy `vdr_requests` lub zmiana statusu): wysyłka **email** (np. SendGrid, Resend, Firebase Extensions – Trigger Email) do Dyrektora Obszaru: „Użytkownik X prosi o dostęp do VDR nieruchomości Y. Zweryfikuj dokumenty.” |
| **Odblokowanie** | Po akceptacji: aktualizacja `user.vdrAccessForListingIds` (array) lub kolekcja `vdr_grants`. Dostęp do sekcji „Dokumenty” na stronie oferty + generowanie linków do pobrania **z watermarkingiem**. |

**Paczki:**

- **Storage:** Firebase Storage (upload PDF).
- **Email:** Cloud Function + Resend / SendGrid / Firebase Trigger Email.
- **Frontend:** `file_picker` / `image_picker` (jeśli tylko PDF, wystarczy picker plików) + widok „Moje wnioski VDR” w dashboardzie.

### 3.3 Dynamiczny znak wodny na PDF

- **Cel:** Przy **pobieraniu** pliku z VDR nakładanie tekstu: np. „Dla: Jan Kowalski, 16.02.2026, IP: X”.
- **Opcje implementacji:**
  1. **Cloud Function (Node):** Na żądanie pobrania (authenticated request) – odczyt oryginalnego PDF z Storage, nałożenie watermarka (np. **pdf-lib**), zapis do tymczasowego pliku, zwrot pliku lub signed URL. Logowanie zdarzenia `document_download` (userId, listingId, documentId, ip, timestamp).
  2. **Dedykowany serwis:** Jeśli dużo ruchu – osobny mikroserwis (Node/Python) z cache’owaniem „zawodnionych” wersji po stronie użytkownika (opcjonalnie).
- **Paczki (Node):** `pdf-lib` (nakładanie tekstu na strony). IP z `request.headers['x-forwarded-for']` lub `request.connection.remoteAddress`.

---

## 4. Reorganizacja frontendu (ścieżki i UX)

### 4.1 Strona główna – dwa główne kafle

- **Kafel „Jestem Inwestorem”**  
  - Główny CTA dla kapitału.  
  - Prowadzi do **bazy ofert (teasery)**.  
  - Na ofercie: przyciski „Zobacz więcej” → wymuszenie Level 2 (logowanie + NDA), potem „Dostęp do dokumentów” → Level 3 (Proof of Funds).  

- **Kafel „Chcę sprzedać nieruchomość / grunt”**  
  - Lead magnet na towar.  
  - Prosty, zachęcający proces (krótki formularz / kroki).  
  - Zgłoszenia trafiają do bazy **„Oczekiwanie”** w panelu admina (Firestore: np. `listing_submissions` ze statusem `pending`).  

- **Kafel „Kalkulator ROI”**  
  - Publiczny, bez logowania.  
  - Na końcu: „Twoje ROI wynosi X% – zobacz nieruchomości o podobnych parametrach” → przekierowanie do rejestracji / bazy ofert (SEO + lead).  

- **Strefa partnera**  
  - **Bez** kafla „Jestem Agentem”.  
  - Mały przycisk **„Zaloguj”** w app bar lub stopce.  
  - Po zalogowaniu: jeśli rola = Agent lub Dyrektor → przekierowanie do **dedykowanego dashboardu** (oferty, statystyki regionu, dokumentacja, wnioski VDR).  

### 4.2 Routing (sugestia)

- `/` – strona główna z kaflami.  
- `/oferty` – baza ofert (teasery dla anonima, pełne dla Level 2).  
- `/oferty/:id` – szczegóły (z sekcją VDR widoczną tylko przy Level 3).  
- `/kalkulator-roi` – kalkulator.  
- `/chce-sprzedac` – formularz zgłoszenia nieruchomości.  
- `/logowanie` – LinkedIn / NIP (oraz ewentualnie hasło w przyszłości).  
- `/dashboard` – po logowaniu: agent/dyrektor/admin według roli.  

---

## 5. Standaryzacja wrzutek (panel agenta)

- **Wymóg:** Formularz oferty z **dynamicznymi polami** w zależności od typu oraz **wymaganymi załącznikami PDF**; bez nich oferta **nie może być opublikowana**.  

### 5.1 Typy i wymagane dane/pliki (szkic)

| Typ | Dodatkowe pola | Wymagane PDF-y |
|-----|----------------|-----------------|
| **Grunt** | WZ/MPZP, wyrys z rejestru gruntów, info o przyłączach | WZ/MPZP, wyrys |
| **Lokal (pustostan)** | Rzut GLA, standard wykończenia, analiza potencjalnego czynszu | Rzut (opcjonalnie w regulaminie) |
| **Obiekt z najemcą** (Lidl, Biedronka itd.) | Umowy najmu, potwierdzenia indeksacji, audyt techniczny, operat | Umowy najmu, operat, audyt (min. zestaw) |

### 5.2 Implementacja

- **Firestore:** Kolekcja `listing_schemas` lub konfig w kodzie: mapa `propertyType → requiredFields[]` i `requiredDocumentTypes[]`.  
- **Flutter:** Formularz dodawania oferty – po wyborze typu ładowana jest odpowiednia konfiguracja (kroki + pola + lista wymaganych załączników).  
- **Walidacja przed publikacją:** Sprawdzenie, czy wszystkie wymagane dokumenty są wypełnione i czy pliki PDF są dodane (np. w Storage + referencje w dokumencie oferty).  
- **Status oferty:** Np. `draft` / `pending_review` / `published`. Publikacja możliwa tylko gdy wymagania spełnione.

---

## 6. Bezpieczeństwo dokumentacji (podsumowanie)

- **VDR:** Dostęp tylko dla użytkowników z `vdrAccessForListingIds` (lub równoważna struktura).  
- **Pobieranie:** Tylko przez backend (Cloud Function), który: weryfikuje token/użytkownika, loguje pobranie (kto, co, kiedy, IP), nakłada watermark i zwraca PDF.  
- **Firestore rules:** Odpowiednie reguły na `listings`, `vdr_requests`, `users`, `proof_of_funds` – brak bezpośredniego odczytu wrażliwych dokumentów z klienta bez sprawdzenia roli i VDR.

---

## 7. Kalkulator ROI

- **Scenariusz 1 – Zakup za gotówkę:**  
  Wejście: cena, przychód roczny (np. czynsz), koszty.  
  Wyjście: **ROI (stopa zwrotu)**, **Payback (czas zwrotu w latach)**.  

- **Scenariusz 2 – Zakup z lewarem (kredyt/leasing):**  
  Wejście: cena, LTV, oprocentowanie, marża, przychód, koszty.  
  Wyjście: **ROE** (rentowność kapitału własnego), wpływ kredytu na cash flow i zwrot.  

- **CTA:** „Twoje ROI wynosi 7% – zobacz nieruchomości o podobnych parametrach” → link do `/oferty?roiMin=6&roiMax=8` + zachęta do rejestracji.  

- **Paczki:** Wystarczy logika w Dart (brak zewnętrznych bibliotek do samego liczenia). Wykresy opcjonalnie: `fl_chart` lub `syncfusion_flutter_charts` (jeśli chcesz wizualizacje).

- **Zapisz kalkulację na e-mail:** Użytkownik może wysłać podsumowanie kalkulacji na podany adres. Dwie ścieżki:
  - **Wyślij na ten adres** – Cloud Function `sendRoiCalculationEmail` (Firebase) wysyła e-mail z Gmail SMTP. Wymaga ustawienia zmiennych środowiskowych w Cloud Functions: `GMAIL_USER` i `GMAIL_APP_PASSWORD` (hasło aplikacji Gmail). Bez tej konfiguracji funkcja zwraca 503, a aplikacja pokazuje komunikat i sugeruje „Otwórz w programie e-mail”.
  - **Otwórz w programie e-mail** – `mailto:` z tematem i treścią (działa bez backendu).

---

## 8. Widok dla Dyrektorów Obszarów

- **Hierarchia:** Admin → Dyrektorzy (np. 4–5 osób) → przypisanie do **województw**. Agenti przypisani do dyrektorów/regionów.  
- **Dane w Firestore:**  
  - `users`: `role` (admin | director | agent), `regionIds` lub `voivodeship` (dyrektor), `directorId` (agent).  
  - Oferty: `regionId` / `voivodeship` (z adresu).  
- **Widok dyrektora:**  
  - Tylko oferty z jego województwa.  
  - Lista agentów w regionie.  
  - Statystyki: kto co pobierał (z logów `document_download`).  
- **Implementacja:** Zapytania Firestore z filtrem `where('voivodeship', isEqualTo: user.voivodeship)` oraz osobna strona „Statystyki / Audyt pobrań”.

---

## 9. Architektura bazy pod przyszły REIT / sprzedaż udziałowa

- **Obecny model:** Oferta = jedna nieruchomość, jeden właściciel/sprzedawca.  
- **Przygotowanie pod udziały:**  
  - Wprowadzenie encji **„Projekt”** lub **„Fundusz”** (jeden projekt = wiele nieruchomości lub jedna z podziałem na udziały).  
  - Kolekcje: `projects`, `project_shares`, `shareholders`.  
  - Pola w ofercie: opcjonalnie `projectId`, `shareType` (full_asset / fractional).  
- **Na teraz:** Wystarczy zaprojektować `listings` z opcjonalnym `projectId` i bez rozbudowy logiki udziałów; ułatwi to późniejsze dodanie modułu REIT bez przebudowy całej bazy.

---

## 10. Rekomendacje techniczne – paczki i narzędzia

### 10.1 Flutter (pubspec.yaml)

| Potrzeba | Paczka | Uwagi |
|----------|--------|--------|
| Auth | `firebase_core`, `firebase_auth` | Logowanie, custom token z Cloud Functions |
| Firestore | `cloud_firestore` | Oferty, użytkownicy, leady, VDR |
| Storage | `firebase_storage` | Upload PDF (Proof of Funds, załączniki ofert) |
| LinkedIn OAuth | Własna integracja przez Cloud Function | W Flutter: `url_launcher` / `webview` do przekierowania na LinkedIn, odbieranie kodu w deep link / web redirect |
| NIP / rejestr | - | Tylko backend (Cloud Function → rejestr.io lub inny API) |
| Pliki PDF (picker) | `file_picker` | Wybór pliku do uploadu |
| Wykresy (kalkulator) | `fl_chart` | Opcjonalnie |

### 10.2 Firebase / backend

- **Cloud Functions (Node 24):**  
  - Custom token (LinkedIn/NIP),  
  - Weryfikacja NIP (wywołanie API rejestru),  
  - Obsługa `vdr_requests`, wysyłka maili do dyrektorów,  
  - Endpoint pobierania dokumentu VDR (watermark + log + zwrot PDF).  
- **Firebase Storage:** Proof of Funds, załączniki ofert, wygenerowane PDF z watermarkiem (krótkotrwałe signed URL).  
- **Firestore:** Reguły bezpieczeństwa dopasowane do ról i poziomów dostępu (teaser / Level 2 / VDR).  
- **Zewnętrzne API:** rejestr.io (lub odpowiednik) – tylko z Functions (klucze po stronie serwera).

### 10.3 Wygląd i UX

- Zachować obecny charakter **premium** (kolory, typografia, spacing).  
- Kafle na stronie głównej: duże, czytelne, jeden główny CTA na kafel („Jestem Inwestorem”, „Chcę sprzedać”).  
- Formularze: kroki z progress barem (już macie w Add Listing), spójne z resztą UI.  
- Dashboard agenta/dyrektora: ciemny lub jasny panel z bocznym menu; lista ofert, tabela wniosków VDR, ekran „Pobrania dokumentów”.

---

## 11. Kolejność wdrożenia (sugestia)

1. **Firebase w aplikacji** – `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, konfiguracja dla web.  
   **Zrobione:** paczki w `pubspec.yaml`, inicjalizacja w `main.dart`, `lib/firebase_options.dart` (placeholder).  
   **Do zrobienia:** Uruchom `dart run flutterfire configure` (wymaga `firebase login`) albo ręcznie uzupełnij w Firebase Console wartości w `lib/firebase_options.dart` (apiKey, appId, messagingSenderId, authDomain, storageBucket).  
2. **Auth + role** – logowanie (na start e-mail/hasło lub tylko Custom Token z Function), role w `users`, przekierowanie po logowaniu.  
3. **Strona główna** – przebudowa na kafle: Inwestor, Chcę sprzedać, Kalkulator ROI + przycisk Zaloguj.  
4. **Baza ofert** – podział na teaser vs pełna oferta, zapytania Firestore z filtrem dostępu.  
5. **NDA + Level 2** – checkbox NDA, zapis w Firestore, odblokowanie Level 2.  
6. **LinkedIn / NIP** – Cloud Functions (OAuth + NIP), Custom Token.  
7. **Formularz „Chcę sprzedać”** – osobny flow, zapis do `listing_submissions` (Oczekiwanie).  
8. **Kalkulator ROI** – widok publiczny + CTA do ofert i rejestracji.  
9. **Panel agenta** – formularz oferty z dynamicznymi polami i wymaganymi PDF; zapis ofert w Firestore.  
10. **VDR** – upload Proof of Funds, kolekcja `vdr_requests`, powiadomienie do dyrektora, ręczne/automatyczne przyznawanie dostępu.  
11. **Watermarking** – Cloud Function do pobierania PDF z watermarkiem i logowaniem.  
12. **Dyrektorzy** – hierarchia regionów, widok „moje województwo”, audyt pobrań.  
13. **Przygotowanie pod REIT** – opcjonalne pola `projectId` / struktura `projects` bez pełnej logiki udziałów.

---

## 12. Pliki do utworzenia / zmiany (skrót)

- **Konfiguracja:** `firebase_options.dart` (FlutterFire CLI), aktualizacja `firestore.rules` i `storage.rules`.  
- **Auth:** `lib/core/auth/` – serwis auth, provider użytkownika i roli.  
- **Modele:** rozszerzenie `Property` / nowy model oferty o `accessLevel`, `vdrDocumentRefs`, pola typu/województwa.  
- **Routing:** nowe ścieżki (oferty, kalkulator, chce-sprzedac, logowanie, dashboard z podziałem na role).  
- **Strona główna:** nowy layout z kaflami.  
- **Cloud Functions:** `onCall` / `onRequest` dla: custom token (LinkedIn/NIP), NIP verification, VDR request, `getDocumentWithWatermark`, trigger email do dyrektora.  
- **Firestore:** kolekcje `users`, `leads`, `listings`, `listing_submissions`, `vdr_requests`, `vdr_grants`, `document_downloads` (log).

Dokument można traktować jako żywy plan: kolejność i szczegóły można doprecyzować w kolejnych iteracjach (np. wybór konkretnego API do NIP, szablonów maili, dokładnych pól formularza per typ nieruchomości).
