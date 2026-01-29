# Analiza UI/UX formularza dodawania ogłoszenia

Analiza obejmuje:
- **Strona główna formularza** – `AddListingPage` (layout, nawigacja między krokami)
- **Wskaźnik postępu** – `StepProgressIndicator`
- **Krok 1: Typ i lokalizacja** – `Step1TypeLocation`
- **Model danych** – `ListingFormData` (walidacja, spójność z UI)

---

## 1. Strona główna formularza (`add_listing_page.dart`)

### Stan obecny
- Scaffold z `AppBarCustom`, kolumna: progress indicator → treść kroku → pasek przycisków (Wstecz / Dalej lub Opublikuj).
- Tylko krok 0 (Typ i lokalizacja) jest zaimplementowany; pozostałe kroki pokazują „Krok X - W budowie”.
- Brak walidacji przed przejściem do następnego kroku; przycisk „Opublikuj” wyświetla tylko SnackBar.

### Ulepszenia UI/UX

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Walidacja** | Użytkownik może iść „Dalej” bez wypełnienia wymaganych pól (np. typ transakcji, typ nieruchomości, miasto) | Blokować „Dalej” dopóki `formData.isStep1Valid()` (i analogicznie dla innych kroków) nie zwróci true; przycisk wyszarzony lub z `onPressed: null` + opcjonalnie krótki komunikat (SnackBar / inline) „Wypełnij wymagane pola”. |
| **Feedback po publikacji** | Tylko SnackBar „Ogłoszenie dodane!” – brak potwierdzenia i dalszej ścieżki | Po sukcesie: dialog potwierdzenia lub przekierowanie na stronę „Ogłoszenie dodane” z linkiem do oferty i CTA (np. „Zobacz ogłoszenie”, „Dodaj kolejne”). Unikać pozostawiania użytkownika na ostatnim kroku formularza. |
| **Zapis w trakcie** | Brak możliwości zapisania szkicu; przy zamknięciu wszystko znika | Opcjonalnie: „Zapisz szkic” (localStorage / backend) oraz ostrzeżenie przy wyjściu (np. `WillPopScope` / `PopScope`): „Masz niewypełnione dane. Na pewno chcesz wyjść?”. |
| **Nawigacja między krokami** | Tylko sekwencyjna (Wstecz/Dalej); nie można skoczyć do konkretnego kroku | W progress indicatorze: klikalne kroki (przynajmniej ukończone) – klik przenosi do danego kroku. Na desktopie opcjonalnie boczne menu z listą kroków. |
| **Przyciski** | Defaultowe `OutlinedButton` / `ElevatedButton` – mogą być niespójne z resztą aplikacji | Użyć `CustomButton` / stylu z projektu (np. jak w promoted listings lub stronie szczegółów), żeby CTA były spójne wizualnie. |
| **Mobile** | Pasek przycisków może być wąski; „Wstecz” i „Dalej” obok siebie | Zachować Row; ewentualnie na bardzo wąskich ekranach pełna szerokość przycisków jeden pod drugim lub sticky bottom bar z wyraźnym cieniem. |
| **Dostępność** | Brak semantics dla kroków i przycisków | Dodać `Semantics` (np. `label: 'Krok 1 z 6, Typ i lokalizacja'`), dla przycisków – czytelne etykiety (np. „Wstecz do kroku Typ”). |

---

## 2. Wskaźnik postępu (`progress_indicator.dart`)

### Stan obecny
- Rząd kółek z numerem/check + etykieta; między krokami linia łącząca (wypełniona gdy ukończone).
- Kolory: `AppColors.accent` dla bieżącego/ukończonego, `AppColors.grey200` dla nieaktywnych.

### Ulepszenia UI/UX

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **6 kroków na mobile** | W jednym rzędzie 6 kroków + etykiety – na wąskim ekranie wszystko się ściszcza, tekst może się obcinać | Na mobile (< 768px): pokazać tylko numer bieżącego kroku i etykietę (np. „Krok 2 z 6: Podstawy”) lub scrollowany poziomy pasek; pełne 6 kółek zostawić na tablet/desktop. |
| **Klikalność** | Kroki nie są klikalne – użytkownik nie może wrócić do np. „Typ” z kroku „Zdjęcia” jednym klikiem | Ukończone kroki (i ewentualnie bieżący) owinąć w `InkWell`/`GestureDetector` i przy kliku wywołać callback `onStepTapped(index)` w `AddListingPage`. |
| **Wizualne wyróżnienie bieżącego** | Bieżący krok = ten sam kolor co ukończony (accent) | Dodać subtelne wyróżnienie: np. obramowanie (ring), lekko większy rozmiar lub krótka animacja pulsowania dla bieżącego kroku; check tylko dla ukończonych. |
| **Etykiety** | `maxLines: 2` – długie etykiety („Szczegóły”, „Podsumowanie”) mogą się zawijać i nierówno wyglądać | Skrócić etykiety na mobile (np. „Podst.” zamiast „Podstawy”) lub jedna linia z `overflow: ellipsis` + tooltip z pełną nazwą. |
| **Dostępność** | Brak informacji dla czytników ekranu | `Semantics`: np. „Krok 2 z 6, Podstawy, ukończone” / „Krok 3 z 6, Szczegóły, bieżący”. |

---

## 3. Krok 1: Typ i lokalizacja (`step1_type_location.dart`)

### Stan obecny
- Trzy sekcje: Typ transakcji (Sprzedaż/Wynajem), Typ nieruchomości (siatka 2×3: Biurowiec, Magazyn, Handlowy, Przemysłowy, Hotel, Działka), Lokalizacja (Miasto, Dzielnica/Osiedle, Ulica).
- Wybór typu: dwa `ElevatedButton`; typ nieruchomości: karty z ikoną i tekstem; lokalizacja: zwykłe `TextField`.

### Ulepszenia UI/UX

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Spójność kolorów** | `Colors.orange`, `Colors.grey[200]`, `Colors.grey` – poza paletą aplikacji (`AppColors`) | Zamienić na `AppColors.accent`, `AppColors.grey200`, `AppColors.grey600` itd., żeby formularz był spójny z resztą aplikacji. |
| **Typ transakcji** | Dwa przyciski obok siebie – wygląd „radio”, ale bez wyraźnej grupy | Dodać nagłówek sekcji (obecny jest tylko „Typ transakcji”) i wizualnie zgrupować (np. `Card` lub obramowanie); rozważyć segmentowany control (chipy) w jednej linii dla spójności z filtrami w wyszukiwarce. |
| **Typ nieruchomości** | `GridView.count` z `shrinkWrap: true` + `NeverScrollableScrollPhysics` – poprawne, ale na bardzo małych ekranach 2 kolumny mogą być ciasne | Zachować 2 kolumny; upewnić się, że karty mają min. ~120px szerokości (np. `childAspectRatio` lub min constraint). Ikony 40px są OK. |
| **Wybór typu nieruchomości** | Brak informacji, że wybór jest wymagany | Dodać krótki hint pod siatką (np. „Wybierz jeden typ”) lub walidację z komunikatem „Wybierz typ nieruchomości”. |
| **Pola lokalizacji** | `TextField` bez `controller` – wartość nie jest przywracana przy powrocie do kroku (formData trzyma dane, ale pole nie ma `initialValue`/controller) | Inicjalizować `TextEditingController` z `formData.city` (i district, street) w `initState`; w `onChanged` zapisywać do `formData` i wywoływać `onDataChanged`. Przy dispose odłączyć controllery. |
| **Pole Miasto** | Brak autouzupełniania i walidacji | Rozważyć autocomplete miast (API lub lokalna lista) oraz walidację „Podaj miasto” przy próbie przejścia dalej. |
| **Pola opcjonalne** | „Dzielnica / Osiedle” i „Ulica (opcjonalnie)” – drugie ma adnotację, pierwsze nie | Dla spójności: przy opcjonalnych polach dodać „(opcjonalnie)” w labelu lub małą podpisową informację „Pola opcjonalne: …”. |
| **Ikona lokalizacji** | Tylko przy „Miasto”; brak ikon przy pozostałych polach adresu | Opcjonalnie: spójne ikony (np. budynek dla dzielnicy, droga dla ulicy) albo zostawić tylko przy Miasto dla prostoty. |
| **Keyboard / focus** | Brak jawnego zarządzania focusem (np. po wejściu na krok) | Na mobile po wejściu na krok nie fokusować od razu pierwszego pola (żeby nie zasłaniać klawiatury); opcjonalnie „Dalej” na klawiaturze przenosi do następnego pola lub zamyka klawiaturę. |
| **Dostępność** | Brak semantics dla grup (typ transakcji, typ nieruchomości) | `Semantics` z `label` i `child` dla grup pól; dla kart typu nieruchomości – np. „Biurowiec, przycisk, wybrany”. |

---

## 4. Model danych i walidacja (`listing_form_model.dart`)

### Stan obecny
- `ListingFormData` z polami dla wszystkich 6 kroków; metody `isStep1Valid()` … `isStep6Valid()`.
- Step 1: `transactionType`, `propertyType`, `city` wymagane.

### Ulepszenia UI/UX (powiązane z modelem)

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Walidacja w UI** | Metody `isStepXValid()` istnieją, ale nie są używane w `AddListingPage` | W `AddListingPage` przy „Dalej”: jeśli nie `formData.isStepXValid()`, nie zmieniać kroku i pokazać komunikat (SnackBar lub inline pod przyciskiem). |
| **Komunikaty błędów** | Brak precyzyjnych komunikatów (które pole jest puste) | Rozszerzyć model lub osobna klasa: np. `validationErrorsForStep1()` zwracająca mapę pole → komunikat; wyświetlać pod konkretnymi polami (np. `errorText` w `InputDecoration`). |
| **Opcjonalność** | W `isStep1Valid()` wymagane jest `city`; brak rozróżnienia „wymagane” vs „opcjonalne” w komentarzach | W modelu lub dokumentacji jasno opisać, które pola są wymagane w każdym kroku; w UI oznaczyć wymagane gwiazdką lub „(wymagane)”. |
| **Spójność typów** | W step 1 używane są wartości jak `office`, `warehouse`; w modelu komentarz mówi o `apartment`, `house` | Zweryfikować komentarze w `ListingFormData` (np. propertyType: commercial types) i upewnić się, że backend / lista typów w aplikacji są z nimi zgodne. |

---

## 5. Kroki 2–6 („W budowie”)

### Rekomendacje na przyszłość

| Krok | Sugestie UI/UX |
|------|----------------|
| **2. Podstawy** | Cena, powierzchnia, pokoje – użyć pól numerycznych z formatowaniem (np. separator tysięcy dla ceny, jednostka m²). Walidacja: cena > 0, powierzchnia > 0. |
| **3. Szczegóły** | Opis: pole wieloliniowe, licznik znaków (min. 50), hint „Opis powinien mieć min. 50 znaków”. Udogodnienia: chipy wielokrotnego wyboru. |
| **4. Zdjęcia** | Upload z podglądem, drag-and-drop lub „Dodaj zdjęcie”; kolejność (przeciągnij); min. 1 zdjęcie z walidacją. Informacja o zalecanym rozmiarze/formacie. |
| **5. Kontakt** | Telefon z maską/formatowaniem; email z walidacją; preferowany czas kontaktu – dropdown lub chipy. |
| **6. Podsumowanie** | Podgląd wszystkich danych + wybór pakietu (Basic/Promoted) i checkbox regulaminu. CTA „Opublikuj” z wyraźnym stylem (np. `CustomButton`). |

---

## 6. Podsumowanie priorytetów

1. **Wysoki:** Walidacja kroków (blokada „Dalej” + użycie `isStep1Valid()` i analogicznie dla innych kroków); przywracanie wartości pól w Step 1 (TextEditingController / initialValue); spójność kolorów z `AppColors`.
2. **Średni:** Klikalne kroki w progress indicatorze; responsywność wskaźnika na mobile; lepszy feedback po publikacji (ekran sukcesu / przekierowanie).
3. **Niski:** Zapisywanie szkicu, ostrzeżenie przy wyjściu; semantics/dostępność; skrócone etykiety kroków na mobile; spójne przyciski (CustomButton).

Po wdrożeniu kroków 2–6 warto powtórzyć analizę pod kątem spójności między krokami (np. ten sam styl pól, te same wzorce walidacji i komunikatów błędów).
