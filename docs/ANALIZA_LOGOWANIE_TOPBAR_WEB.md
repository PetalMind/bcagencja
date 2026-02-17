# Analiza: logowanie, przesył danych i dynamiczny topbar (web)

## 1. Funkcjonalność logowania

### 1.1 Przepływ

- **Źródło stanu**: `currentUserProvider` (Riverpod `StreamProvider`) łączy Firebase Auth (`authStateChanges`) z profilem z Firestore (`users/{uid}`). Zwraca `AppUser?` (rola, accessLevel, NDA, VDR).
- **Wejście**: użytkownik trafia na `/logowanie` (opcjonalnie z `?returnTo=/oferty` lub `/property/123`).
- **Metody logowania**:
  - **Web**: Google/Apple przez `signInWithPopup()` (Firebase Auth).
  - **Desktop/mobile**: Google przez `google_sign_in`, Apple przez `sign_in_with_apple` (z nonce).
  - **Wszędzie**: email/hasło (`signInWithEmailAndPassword` / `createUserWithEmailAndPassword`).
- **Po zalogowaniu**:
  - Jeśli `hasIdentityVerifiedAccess` → przekierowanie do `returnTo` lub `/dashboard`.
  - W przeciwnym razie → `/weryfikacja?returnTo=...` (NDA, NIP/LinkedIn).
- **Persistence (tylko web)**: przed logowaniem email/hasło wywoływane jest `setPersistence(Persistence.local | session)` w zależności od „Zapamiętaj mnie”.

### 1.2 Potencjalne problemy na web

| Problem | Opis | Rekomendacja |
|--------|------|---------------|
| **Blokada popup** | Google/Apple na web używają `signInWithPopup`. Blokada popupów w przeglądarce przerywa logowanie bez czytelnego komunikatu. | Obsłużyć błąd (np. `popup-blocked`), pokazać komunikat i ewentualnie fallback na `signInWithRedirect` + odczyt stanu po powrocie. |
| **Redirect vs popup** | `signInWithRedirect` zmienia kontekst (cała strona odchodzi), co może gubić `returnTo` trzymane tylko w pamięci. | Przy redirectzie trzymać `returnTo` w `sessionStorage`/query przed redirectem i odczytać po powrocie. |
| **Apple na web** | `signInWithApple` na web jest w kodzie (`signInWithPopup(AppleAuthProvider)`), ale w UI Apple jest ukryte (`showApple = !kIsWeb`). | Albo włączyć Apple na web (wymaga konfiguracji w Apple Developer + domeny), albo zostawić ukryte i udokumentować. |
| **Remember me** | `SharedPreferences` na web = local storage. Działa, ale `_loadRememberMe()` w `initState` używa `ref.read(sharedPreferencesProvider)` – przy pierwszym wejściu provider może nie być jeszcze gotowy. | Rzadki edge case; w razie problemów ładować „remember me” w `main` lub z opóźnieniem. |
| **Podwójne przekierowanie** | Gdy użytkownik jest już zalogowany, `LoginPage` w `build` wywołuje `addPostFrameCallback` z `context.go(...)`. Przy szybkim odświeżeniu streamu możliwy double-navigation. | Sprawdzić `context.mounted` i ewentualnie użyć jednej flagi „redirect już wykonany”. |
| **ReCAPTCHA / App Check** | W `index.html` jest `FIREBASE_APPCHECK_DEBUG_TOKEN = true` – na produkcji trzeba to usunąć i mieć prawdziwy klucz reCAPTCHA Enterprise. Bez tego zapisy (np. Firestore) mogą być blokowane. | W prod: wyłączyć debug token, ustawić prawidłowy `recaptchaEnterpriseSiteKey` w `AppConfig`. |

---

## 2. Przesył danych

### 2.1 Kanały

- **Firebase Auth**: logowanie, tokeny, persistence (web). Nie przesyłasz „własnych” danych użytkownika poza tym, co Auth zwraca.
- **Firestore**:
  - Odczyt: `users/{uid}` (profil: rola, accessLevel, NDA, VDR).
  - Zapis: `AuthService._ensureUserProfile`, `acceptNdaAndGrantLevel2`, `ListingSubmissionService.submit` → `listing_submissions`.
- **HTTP API**: `WlApiClient` → `https://wl-api.mf.gov.pl` (weryfikacja NIP). Używane z poziomu weryfikacji konta.
- **App Config**: `apiBaseUrl = 'https://api.bcagencja.pl'` – zdefiniowany, ale w tej analizie nie widać jeszcze wywołań tego API (np. oferty z backendu).

### 2.2 Potencjalne problemy (web)

| Problem | Opis | Rekomendacja |
|--------|------|---------------|
| **CORS** | Firestore/Firebase Auth działają z własną domeną; WL API jest zewnętrzne. Na web CORS ustawia serwer (wl-api.mf.gov.pl). | Obsłużyć błędy sieciowe w `WlApiClient` i pokazać komunikat (np. „Tymczasowo niedostępne”). |
| **App Check (web)** | App Check z reCAPTCHA Enterprise musi być skonfigurowany dla domeny (w tym localhost z debug tokenem). Bez poprawnej konfiguracji zapisy do Firestore mogą zwracać błąd. | Przetestować zapis do Firestore na web (np. rejestracja, zgłoszenie „Chcę sprzedać”) z włączonym App Check. |
| **Bezpieczeństwo reguł** | Dane użytkowników i zgłoszeń są w Firestore. Reguły Firestore muszą ograniczać odczyt/zapis do `users/{uid}` i do odpowiednich ról dla `listing_submissions`. | Przegląd reguł Firestore (Security Rules) po stronie projektu. |
| **Sesja / token** | Na web Firebase Auth trzyma sesję w IndexedDB (local) lub session storage (session). Wygaśnięcie tokena może objawić się dopiero przy następnym żądaniu do Firestore. | Riverpod `currentUserProvider` reaguje na `authStateChanges`, więc wylogowanie/expiry powinno odświeżyć UI; warto ewentualnie obsłużyć błędy „permission-denied” i wymusić re-login. |

---

## 3. Dynamiczny topbar (web)

### 3.1 Zachowanie

- **Komponent**: `AppBarCustom` (`lib/widgets/navigation/app_bar_custom.dart`) – `ConsumerWidget`, `ref.watch(currentUserProvider)`.
- **Logika**:
  - **Anonim**: przyciski nawigacji (Szukaj, O nas, Blog, Kontakt), „Zaloguj”.
  - **Zalogowany**: opcjonalnie „Zweryfikuj konto”, „Wyloguj”, opcjonalnie „Dodaj ogłoszenie” (gdy `hasPartnerDashboard`), ikona „Panel”.
  - **Ładowanie**: gdy `asyncUser.isLoading` – w actions wyświetlany jest mały `CircularProgressIndicator` zamiast „Zaloguj”/„Wyloguj”.
- **Breakpoint**: `isMobile = MediaQuery.of(context).size.width < 768` – na mobile hamburger (drawer), na desktop pełne przyciski w pasku.

### 3.2 Potencjalne problemy na web

| Problem | Opis | Rekomendacja |
|--------|------|---------------|
| **Opóźnienie stanu auth** | `currentUserProvider` to stream: najpierw `authStateChanges`, potem `getAppUser(uid)` z Firestore. Na słabym łączu przez ułamek sekundy topbar może pokazywać „Zaloguj” zamiast „Wyloguj”, albo odwrotnie po wylogowaniu. | Zaakceptować krótkie migotanie lub dodać prosty „skeleton” w miejscu akcji auth (np. szary placeholder), aż `asyncUser` ma wartość (success/error). |
| **Przepełnienie actions** | Na desktop w actions są: Szukaj, O nas, Blog, Kontakt, (Zweryfikuj), (Zaloguj/Wyloguj/loading), (Dodaj ogłoszenie), (Panel). Przy wąskim oknie lub dużej czcionce pasek może się zawijać lub przycinać. | Użyć `Flexible`/`Wrap` w actions lub ograniczyć liczbę widocznych linków (np. „Więcej” → menu), albo zmniejszyć padding/rozmiar fontu w breakpointach. |
| **Niespójność z MobileMenu** | Topbar i `MobileMenu` (drawer) budują stan z tego samego `currentUserProvider`, więc logika (Zaloguj / Wyloguj / Panel / Dodaj) jest spójna. Jednak w topbarze „Szukaj” prowadzi do `AppRouter.search`, a w menu mobilnym „Oferty komercyjne” do `AppRouter.oferty` – to celowo dwa różne ekrany (wyszukiwarka vs lista ofert). | Wystarczy udokumentować różnicę; ewentualnie w topbarze dodać też link „Oferty” dla symetrii. |
| **`context` po async** | W `AppBarCustom` przy „Wyloguj” wywołuje się `await auth.signOut(); if (context.mounted) context.go(...)`. Sprawdzenie `mounted` jest poprawne. | Bez zmian. |
| **Strony bez AppBarCustom** | Większość stron używa `AppBarCustom`; `app_router.dart` ma jeden `AppBar` (np. przy błędzie 404). Trzeba pilnować, żeby nowe ekrany też używały `AppBarCustom`, jeśli mają mieć spójny stan logowania. | W code review zwracać uwagę na użycie `AppBarCustom` vs `AppBar`. |

### 3.3 Inne uwagi

- **Stała wysokość**: `preferredSize = Size.fromHeight(kToolbarHeight)` – brak problemów z layoutem.
- **Brak bezpośredniego odwołania do platformy**: topbar nie używa `kIsWeb`; zachowanie zależy tylko od `MediaQuery` i Riverpod, więc działa tak samo na web i na innych platformach.

---

## 4. Podsumowanie

- **Logowanie**: przepływ jest spójny (Auth + Firestore, returnTo, weryfikacja). Na web warto dopracować obsługę blokady popupów i (opcjonalnie) redirect dla Google/Apple oraz upewnić się, że App Check i klucze reCAPTCHA są poprawne na produkcji.
- **Dane**: Firestore + WL API; na web kluczowe są CORS (po stronie WL), App Check i reguły bezpieczeństwa Firestore.
- **Topbar**: dynamiczny stan z Riverpoda jest poprawny; na web możliwe jest krótkie „mignięcie” stanu przy pierwszym ładowaniu lub po logowaniu/wylogowaniu oraz ryzyko przepełnienia actions na wąskich desktopach – można to złagodzić przez skeleton lub uproszczenie paska.
