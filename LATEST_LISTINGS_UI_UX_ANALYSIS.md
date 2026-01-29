# Analiza UI/UX – sekcja „Najnowsze ogłoszenia”

Analiza komponentu `LatestListings` (`lib/features/home/widgets/latest_listings.dart`) – karty ofert na stronie głównej.

---

## 1. Stan obecny

- **Nagłówek:** Tylko tekst „Najnowsze ogłoszenia”, bez CTA.
- **Siatka:** Grid 1/2/4 kolumny (mobile/tablet/desktop), `childAspectRatio: 0.75`.
- **Karta:** Własna implementacja `_buildListingCard` – obrazek 150px, cena, tytuł, m² + pokoje.
- **Interakcja:** `GestureDetector` + `Card`; brak hover, brak `InkWell`.
- **Obrazek:** `Image.network` z `errorBuilder`, **bez** `loadingBuilder`.
- **Dane na karcie:** Brak lokalizacji, brak licznika zdjęć, brak daty „X dni temu”.

---

## 2. Porównanie z innymi komponentami

| Cecha | LatestListings | ListingGridTile (wyniki) | PromotedListings |
|-------|----------------|--------------------------|------------------|
| CTA „Zobacz wszystkie” | ❌ | — | ✅ CustomButton |
| Hover (elevation + scale) | ❌ | ✅ MouseRegion, AnimatedScale | ✅ |
| InkWell (splash) | ❌ | ✅ | ✅ |
| Loading obrazka | ❌ | ✅ CircularProgressIndicator | ✅ |
| Licznik zdjęć | ❌ | ✅ badge „N” | ✅ |
| Lokalizacja | ❌ | ✅ property.location | ✅ |
| Wspólny komponent | — | — | Własny _PromotedCard |

**Wniosek:** Karty „Najnowsze ogłoszenia” są uboższe niż `ListingGridTile` i nie korzystają z tego samego komponentu, co prowadzi do niespójności i duplikacji kodu.

---

## 3. Rekomendacje zmian

### 3.1 Nagłówek i CTA (wysoki priorytet)

| Problem | Rekomendacja |
|--------|--------------|
| Brak możliwości przejścia do pełnej listy | Dodać w jednej linii z tytułem przycisk/link **„Zobacz wszystkie”** (jak w „Promowane oferty”) – `CustomButton` z `ButtonVariant.text`, nawigacja do `AppRouter.searchResults`. |
| Tylko suchy tytuł | Opcjonalnie krótki podtytuł, np. „Świeże oferty komercyjne” lub zostawić minimalistycznie. |

### 3.2 Wspólna karta z wynikami wyszukiwania (wysoki priorytet)

| Problem | Rekomendacja |
|--------|--------------|
| Duplikacja logiki karty | **Użyć `ListingGridTile`** zamiast `_buildListingCard`. Jednolity wygląd listingu na stronie głównej i w wynikach wyszukiwania, mniej kodu do utrzymania. |
| Brak hover i feedbacku | `ListingGridTile` ma już `MouseRegion`, `AnimatedScale`, `InkWell` – po reużyciu automatycznie zyskasz hover i splash. |

### 3.3 Jakość obrazka (średni priorytet)

| Problem | Rekomendacja |
|--------|--------------|
| Brak wskaźnika ładowania | W `ListingGridTile` jest `loadingBuilder` z `CircularProgressIndicator` – po reużyciu problem znika. |
| Brak informacji o liczbie zdjęć | W `ListingGridTile` jest badge z liczbą zdjęć – po reużyciu użytkownik zobaczy „ile zdjęć ma oferta”. |

### 3.4 Treść karty (średni priorytet)

| Problem | Rekomendacja |
|--------|--------------|
| Brak lokalizacji | `ListingGridTile` pokazuje `property.location` pod tytułem – po reużyciu karty „Najnowsze” będą miały lokalizację. |
| Brak „świeżości” | Mały tekst „Dodane X dni temu” (jak w `ListingCard`) w `ListingGridTile`. | ✅ Wdrożone |

### 3.5 Dostępność i semantyka (niski priorytet)

| Problem | Rekomendacja | Status |
|--------|--------------|--------|
| Brak semantics | Dodać `Semantics` na kartę (np. `label` z ceną + tytułem) oraz `semanticLabel` przy ikonie ulubionych („Dodaj do ulubionych”). | ✅ Wdrożone w `ListingGridTile` |
| Ulubione bez stanu „zapisane” | Ikona zależna od stanu (np. `favorite` vs `favoriteBorder`) i integracja z `FavoritesProvider` (jak w promoted). | ✅ Wdrożone w `ListingGridTile` |

### 3.6 Layout i responsywność (niski priorytet)

| Obszar | Uwaga |
|--------|--------|
| `childAspectRatio: 0.75` | Obecna wartość jest OK; jeśli po dodaniu lokacji karta będzie za wysoka, można zmniejszyć do 0.72 lub dostosować padding. |
| Tło sekcji | `AppColors.backgroundGrey` – spójne z resztą strony; bez zmian. |

---

## 4. Proponowana kolejność wdrożenia

1. **Dodać CTA „Zobacz wszystkie”** w nagłówku (Row + CustomButton), nawigacja do wyników wyszukiwania.
2. **Zastąpić `_buildListingCard`** komponentem **`ListingGridTile`** – jedna zmiana, wiele benefitów (hover, loading, licznik zdjęć, lokalizacja).
3. ~~Opcjonalnie: w `ListingGridTile` dodać wyświetlanie daty „X dni temu”.~~ ✅ Wdrożone.
4. ~~Opcjonalnie: semantics i stan ulubionych w kartach.~~ ✅ Wdrożone (Semantics na karcie, semanticLabel przy ulubionych, FavoritesProvider).

---

## 5. Podsumowanie

- Główne problemy: **brak CTA**, **osobna, uboższa karta** (bez hover, ładowania, lokacji, licznika zdjęć).
- Najprostsza i najbardziej skuteczna poprawka: **CTA w nagłówku** + **reużycie `ListingGridTile`** w sekcji „Najnowsze ogłoszenia”.
