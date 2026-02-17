# Analiza: dlaczego aplikacja może się nie uruchamiać w Safari

**Data:** 17.02.2026  
**Kontekst:** Flutter web (bcagencja) – potencjalne przyczyny braku uruchomienia lub błędów w Safari / WebKit.

---

## 1. Główne obszary ryzyka

### 1.1 Renderer Flutter (CanvasKit / WebGL)

- **Build:** `flutter build web` (bez `--wasm`) używa domyślnie renderera **CanvasKit**, który opiera się na **WebGL**.
- **Safari:** W Safari WebGL w kontekście **Web Workers** (używanych przez Flutter/CanvasKit) może być zablokowany lub działać wadliwie.
- **Efekt:** Biały ekran, aplikacja „nie startuje”, w konsoli błędy typu WebGL / `WEBGL_polygon_mode` / worker.

**Co już jest w projekcie:** W `web/index.html` jest komentarz o włączeniu w Safari:  
*Develop → Experimental Features → Allow WebGL in Web Workers.*

**Rekomendacja:**  
- Dla użytkowników: włączyć tę opcję (jeśli dostępna).  
- **Zastosowano:** W projekcie dodano plik **`web/flutter_bootstrap.js`**, który dla Safari wymusza **CanvasKit w trybie CPU-only** (`canvasKitForceCpuOnly: true`), co pozwala uniknąć błędów WebGL bez włączania „Allow WebGL in Web Workers”.

---

### 1.2 Firebase Auth – redirect (Google / Apple) i Safari

- Na **web** logowanie przez Google/Apple używa **signInWithRedirect** + **getRedirectResult()**.
- W **Safari** (zwłaszcza z zaostrzoną prywatnością, ITP, blokowaniem ciasteczek third-party) **getRedirectResult()** może rzucać wyjątkiem (np. COOP, brak ciasteczek).
- **Efekt:** Gdyby wyjątek nie był złapany, cała aplikacja mógłaby się nie uruchomić.

**Co już jest w projekcie:** W `lib/main.dart` wywołanie `handleWebRedirectResult()` jest w **try/catch** – błąd jest ignorowany, start aplikacji nie jest przerywany. To jest poprawne.

**Rekomendacja:** Zostawić obecną obsługę; ewentualnie dodać (w trybie debug) logowanie błędu, żeby w razie problemów użytkownika wiedzieć, że chodzi o auth redirect.

---

### 1.3 SharedPreferences (IndexedDB) na Safari

- **SharedPreferences** na web korzysta z **IndexedDB** (localStorage itd.).
- W **Safari w trybie prywatnym** lub przy blokadzie storage IndexedDB może być niedostępny – `SharedPreferences.getInstance()` rzuca.
- **Efekt:** Gdyby wyjątek nie był obsłużony, start mógłby się wysypać.

**Co już jest w projekcie:** W `main.dart` `SharedPreferences.getInstance()` jest w **try/catch**; przy błędzie używane jest `prefs = null` i aplikacja startuje z `sharedPreferencesProvider` nadpisanym na null (ulubione nie są wtedy persystowane). To jest poprawne.

**Rekomendacja:** Zostawić obecną obsługę.

---

### 1.4 crypto.randomUUID

- **Firebase / Auth** mogą korzystać z **crypto.randomUUID()**, które w starszych Safari lub w pewnych kontekstach nie istnieje.
- **Co już jest w projekcie:** W `web/index.html` jest **polyfill** dla `crypto.randomUUID` – brak tej funkcji nie powinien już blokować startu.

---

### 1.5 Build WASM (--wasm) i Safari

- Przy **flutter build web --wasm** Flutter może używać **skwasm** (WasmGC). **Safari** ma ograniczone lub brakujące wsparcie dla WasmGC w starszych wersjach.
- Dla **standardowego** `flutter build web` (bez `--wasm`) używany jest tylko **CanvasKit** (bez WasmGC w głównym kanale). Problem dotyczy głównie buildów z `--wasm`.

**Rekomendacja:** Na ten moment budować **bez** `--wasm` (`flutter build web`), żeby uniknąć problemów WasmGC w Safari. Gdy Safari będzie w pełni wspierać WasmGC, można wrócić do rozważenia `--wasm`.

---

### 1.6 Nagłówki COOP/COEP i SharedArrayBuffer

- Tryb **wielowątkowy** renderera **skwasm** wymaga **SharedArrayBuffer**, co z kolei wymaga nagłówków **COOP/COEP**.
- **Firebase Hosting** w `firebase.json` nie ustawia tych nagłówków – wielowątkowy skwasm i tak nie będzie w pełni wykorzystany; ewentualne problemy Safari z SharedArrayBuffer nie powinny więc blokować startu przy obecnym (domyślnym) buildie bez `--wasm`.

---

## 2. Podsumowanie: co może faktycznie „zablokować” start w Safari

| Przyczyna                          | Ryzyko | Stan w projekcie |
|------------------------------------|--------|-------------------|
| WebGL / CanvasKit w workerze       | **Wysokie** | Komentarz w HTML; można dodać CPU-only dla Safari |
| getRedirectResult() (Auth)         | Niskie | try/catch w main.dart |
| SharedPreferences (IndexedDB)      | Niskie | try/catch, prefs = null |
| crypto.randomUUID                  | Niskie | Polyfill w index.html |
| WasmGC (build --wasm)              | Średnie | Nie używany przy zwykłym build web |

Najbardziej prawdopodobna przyczyna **„aplikacja się nie uruchamia”** w Safari to **WebGL w kontekście CanvasKit** (np. Web Workers). Drugą w kolejności byłby ewentualny błąd **przed** obsłużonymi blokami try/catch (np. inicjalizacja Firebase), który nie jest jeszcze łapany.

---

## 3. Propozycje zmian

### 3.1 Wymuszenie CanvasKit CPU-only dla Safari ✅

Zaimplementowano w **`web/flutter_bootstrap.js`**: wykrywanie Safari (userAgent + vendor) i wywołanie `_flutter.loader.load({ config: { canvasKitForceCpuOnly: true } })` tylko dla Safari. Po zmianach w `web/` należy przebudować: `flutter build web`.

### 3.2 Build tylko z CanvasKit (bez WASM)

- Używać **`flutter build web`** (bez `--wasm`), żeby nie wchodzić w WasmGC/skwasm na Safari.

### 3.3 Testy w Safari

- Otworzyć aplikację w **Safari** (macOS i ewentualnie iOS).
- Włączyć **Develop → Show JavaScript Console** i sprawdzić, czy przy starcie pojawiają się błędy (WebGL, worker, Auth, IndexedDB).
- Przetestować zarówno tryb normalny, jak i **prywatny** (logowanie i ulubione mogą nie być zapisywane – to oczekiwane).

---

## 4. Szybki checklist dla użytkownika (Safari)

- W **Safari** (macOS): **Develop → Experimental Features → Allow WebGL in Web Workers** – włączyć, jeśli aplikacja się nie ładuje.
- Upewnić się, że **JavaScript** nie jest wyłączony w ustawieniach Safari.
- W trybie **prywatnym**: ulubione i stan logowania po przekierowaniu mogą nie być zapisywane – to ograniczenie storage/cookies, nie błąd aplikacji.

---

*Dokument przygotowany na podstawie analizy repozytorium bcagencja (Flutter web, Firebase Auth, SharedPreferences, web/index.html, main.dart).*
