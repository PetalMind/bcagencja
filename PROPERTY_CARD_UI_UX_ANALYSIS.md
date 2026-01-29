# Analiza UI/UX kart produktu (nieruchomości) – rekomendacje ulepszeń

Analiza obejmuje:
- **Karty listingu** – `ListingCard`, `ListingGridTile` (wyniki wyszukiwania)
- **Strona szczegółów** – `PropertyDetailPage` + galeria, panel info, parametry, udogodnienia
- **Promowane oferty** – karty na stronie głównej

---

## 1. Karty listingu (`listing_card.dart`, `listing_grid_tile.dart`)

### Stan obecny
- Card z elevation 2, obrazek po lewej (list) / u góry (grid).
- Cena, tytuł, lokalizacja, parametry (m², pokoje, piętro), ikony udogodnień.
- Przycisk „Kontakt” w widoku listy; brak w gridzie.
- Ulubione: IconButton z półprzezroczystym tłem.

### Ulepszenia UI/UX

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Feedback wizualny** | Brak wyraźnego stanu hover/focus na całej karcie | Dodać `hoverColor`/`splashColor` w `InkWell`, lekki scale lub cień przy hover (np. elevation 4). |
| **Obrazek** | Stałe wymiary (150×180 / 150×150); na małych ekranach może być nieczytelne | Użyć `AspectRatio` (np. 4:3) zamiast sztywnych pikseli; `BoxFit.cover` zostaje. |
| **Licznik zdjęć** | Brak informacji, ile zdjęć ma oferta | W prawym dolnym rogu zdjęcia: badge „1/5” lub ikona galerii + liczba (jak w `promoted_listings`). |
| **Ulubione** | Brak stanu „zapisane” (wypełniona ikona) | Ikona zależna od stanu (np. `favorite` vs `favoriteBorder`); opcjonalnie krótka animacja. |
| **Data** | „X dni temu” liczone od `createdAt` – może być ujemne przy mockach | Zabezpieczyć: `difference.inDays.abs()` i obsłużyć przyszłe daty. |
| **Przycisk Kontakt** | Defaultowy `ElevatedButton` – słabo spójny z resztą UI | Użyć `CustomButton` (jak w promoted) lub styl outline; ten sam styl co „Zadzwoń” / „Napisz” na stronie szczegółów. |
| **Dostępność** | Brak semantics / aria dla ceny i akcji | Dodać `Semantics` (np. `label` z ceną i tytułem); dla ulubionych – `semanticLabel: 'Dodaj do ulubionych'`. |
| **Ładowanie obrazka** | Tylko `errorBuilder`; brak wskaźnika ładowania | Dodać `loadingBuilder` z `CircularProgressIndicator` (wzór jak w `promoted_listings`). |
| **Grid – brak CTA** | W gridzie użytkownik tylko klika kartę | Opcjonalnie mały link „Szczegóły” lub ikona strzałki w rogu karty. |

---

## 2. Strona szczegółów nieruchomości (`property_detail_page.dart` + widgety)

### 2.1 Nagłówek (tytuł, lokalizacja, statystyki)

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Breadcrumbs** | Tylko desktop; brak linków | Zrobić klikalne linki (Strona główna → Wyszukiwanie → Miasto → Typ); na mobile dodać uproszczone breadcrumbs lub „Wróć do wyników”. |
| **Statystyki (wyświetlenia, polubienia, data)** | Długi w jednej linii; na wąskim ekranie się ściska | Na mobile: zawinąć w 2 linie lub pokazać w formie chipów / ikon z tooltipem. |
| **Zweryfikowane** | Dobre; brak krótkiej informacji „co to daje” | Opcjonalnie `Tooltip` lub mały link „Co to znaczy?” przy odznace. |

### 2.2 Galeria (`property_gallery.dart`)

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Wysokość głównego zdjęcia** | Stała 400px – na desktopie traci proporcje | Użyć max height + `AspectRatio` (np. 16:10) lub responsywnej wysokości z `LayoutBuilder`. |
| **Nawigacja** | Tylko miniatury; brak strzałek na głównym zdjęciu | Dodać strzałki L/R na głównym obrazku (szczególnie desktop); na mobile – swipe jest OK. |
| **Lightbox** | Brak wskaźnika „3/12” i możliwości zamknięcia gestem | W dialogu: licznik zdjęć (np. u góry) i możliwość zamknięcia przez swipe w dół lub klik poza obrazem. |
| **Miniatury** | Poziomy scroll – brak oznaczenia „jest więcej” | Delikatny gradient lub cień po prawej gdy są kolejne zdjęcia; opcjonalnie strzałka „więcej”. |
| **Ładowanie** | Brak placeholderów przy przełączaniu zdjęć | Skeleton lub mały `CircularProgressIndicator` w rogu podczas zmiany zdjęcia. |

### 2.3 Panel informacyjny (`property_info_panel.dart`)

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Sticky na desktop** | Panel znika przy scrollu | Na desktop: `position: sticky` (np. `Align` + `SingleChildScrollView` w kolumnie) albo osobny widget sticky, żeby cena i CTA były zawsze widoczne. |
| **Hierarchia CTA** | Telefon i „Zapisz” / „Udostępnij” na jednym poziomie | Główny CTA: „Zadzwoń” (lub „Napisz”); „Zapisz” i „Udostępnij” jako przyciski drugorzędne (outline/tekst). |
| **Formularz kontaktu** | Brak w mobile (jest tylko MobileContactBar) | Na mobile w sekcji „Opis” lub pod galerią dodać zwinięty blok „Napisz do ogłoszeniodawcy” (rozwijany). |
| **Udostępnij** | Brak realnej funkcji | Dodać `Share.share()` (package `share_plus`) z linkiem i tytułem oferty. |

### 2.4 Opis (`property_description.dart`)

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Długi tekst** | Brak „Czytaj więcej” | Przy długim opisie (>3–4 linie): domyślnie skrócony tekst + przycisk „Pokaż więcej” rozwijający resztę. |
| **Formatowanie** | Płaski tekst | Jeśli API zwraca HTML/Markdown – renderować listy i pogrubienia (np. `flutter_html` lub `markdown`). |

### 2.5 Parametry techniczne (`property_parameters.dart`)

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Czytelność** | Długa lista w jednej tabeli | Sekcje (np. „Podstawowe”, „Finansowe”, „Najem”) z nagłówkami lub accordion. |
| **Ostatni wiersz** | `_buildRow` z `border: bottom` – ostatni wiersz ma niepotrzebną linię | Ostatni wiersz bez dolnego bordera lub użyć `ListView.separated` z `Divider`. |
| **Mobile** | Szeroka tabela na wąskim ekranie | Na bardzo wąskich ekranach: układ pionowy (label nad wartością) zamiast dwóch kolumn. |

### 2.6 Udogodnienia (`property_amenities.dart`)

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Duża liczba ikon** | Długi grid bez grupowania | Grupy: „Bezpieczeństwo”, „Infrastruktura”, „Biuro” itd. z nagłówkami. |
| **Spójność ikon** | Część z `AppIcons`, część z `Icons` | Ujednolicić do jednego zestawu (najlepiej AppIcons) dla spójnego wyglądu. |
| **Hover** | Brak feedbacku na kafelku | Lekki cień lub obramowanie przy hover (desktop). |

### 2.7 Sekcja lokalizacji

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Mapa** | Placeholder bez działania | Integracja z Google Maps / Mapy.cz (iframe lub plugin) z pinezką; link „Otwórz w mapach”. |
| **„Dostęp i infrastruktura”** | Dane na sztywno (3 km, 15 km…) | Pobierać z API lub konfiguracji; w razie braku danych – sekcja ukryta lub „Brak danych”. |

### 2.8 Mobile – dolny pasek (`mobile_contact_bar.dart`)

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Sticky** | Bar może zasłaniać treść | Upewnić się, że ostatnia sekcja (np. „Podobne”) ma `paddingBottom` równy wysokości bara. |
| **Dostępność** | Przyciski bez semantics | `Semantics` dla „Zadzwoń” i „Napisz” (np. `label` z numerem). |

---

## 3. Promowane oferty (`promoted_listings.dart`)

| Obszar | Problem | Rekomendacja |
|--------|--------|--------------|
| **Spójność z listing_card** | Inny layout (typu karta z góry) i inne detale | Wspólny komponent „PropertyCard” z wariantami: `compact` (grid), `list`, `promoted` – jedna paleta i te same wzorce (badge, ulubione, licznik zdjęć). |
| **Hover** | Brak | Lekka podniesienie karty (elevation) lub delikatny scale (np. 1.02) przy hover. |
| **Ładowanie** | Jest `loadingBuilder` – OK | Wzorować to samo w `ListingCard` i `ListingGridTile`. |

---

## 4. Wspólne rekomendacje

### Wzorce
- **Jednolity komponent karty** – jedne style, stany (hover, ulubione, ładowanie, błędy obrazka) dla list/grid/promoted.
- **Sticky CTA** – na stronie szczegółów cena + „Zadzwoń”/„Napisz” zawsze dostępne (desktop: panel, mobile: dolny bar).
- **Szkielety ładowania** – zamiast pustych białych kart przy ładowaniu listy ofert.

### Dostępność
- Semantics dla cen, linków i przycisków (w tym ulubione, udostępnij).
- Kontrast: sprawdzić tekst drugorzędny (grey600) na tle białym (WCAG AA).
- Nawigacja klawiaturą / focus: widoczny focus na kartach i przyciskach.

### Wydajność
- Galeria: lazy load zdjęć poza viewportem; niższa rozdzielczość dla miniaturek.
- Obrazki w listach: `cacheWidth`/`cacheHeight` (np. 300×200) żeby ograniczyć zużycie pamięci.

### Mikrointerakcje
- Klik „Ulubione”: krótka animacja (np. scale + zmiana ikony).
- Po „Udostępnij”: snackbar „Skopiowano link” lub „Udostępniono”.
- Po wysłaniu formularza kontaktu: komunikat sukcesu i opcjonalnie ukrycie formularza.

---

## 5. Priorytety wdrożenia

**Wysoki (szybki wpływ na UX)**  
1. Sticky panel z ceną i CTA na desktop.  
2. „Pokaż więcej” w opisie.  
3. Licznik zdjęć na kartach listingu + loadingBuilder dla obrazków.  
4. Działające „Udostępnij” (share).  
5. Breadcrumbs jako linki.

**Średni**  
6. Jednolity komponent karty (refactor ListingCard / GridTile / Promoted).  
7. Strzałki i licznik w lightboxie galerii.  
8. Hover na kartach (cień/scale).  
9. Grupowanie parametrów / udogodnień.  
10. Mapa z prawdziwą integracją.

**Niski**  
11. Tooltip przy „Zweryfikowane”.  
12. Semantics i aria na całej stronie.  
13. Skeleton loading dla listy ofert.

Mogę pomóc wdrożyć wybrane punkty (np. sticky panel, „Pokaż więcej” w opisie, licznik zdjęć i loading w kartach) – napisz, od czego chcesz zacząć.
