# 🎨 Custom Button Widget - Przewodnik

## Przegląd

`CustomButton` to nowoczesny, reużywalny widget przycisków zaprojektowany w stylu geometrycznego designu aplikacji. Przyciski zawierają:

- ✨ Animowane efekty hover z geometrycznymi elementami
- 🎨 5 wariantów stylistycznych
- 📏 3 rozmiary
- 🔄 Animacje press/release
- ♿ Wsparcie dla accessibility
- 🎯 Ikony leading/trailing
- ⏳ Stan loading
- 📱 Responsywny design

## Warianty Przycisków

### 1. Primary Button
Główny przycisk call-to-action w kolorze akcentowym (#BE6E59).

```dart
CustomButton(
  label: 'Szukaj nieruchomości',
  icon: AppIcons.search,
  variant: ButtonVariant.primary,
  size: ButtonSize.large,
  onPressed: () {
    // Action
  },
)
```

**Użycie:**
- Główne akcje na stronie
- Wysyłanie formularzy
- Kluczowe call-to-action

### 2. Gradient Button
Premium przycisk z gradientem i animowanym geometrycznym tłem.

```dart
CustomButton(
  label: 'Dodaj ogłoszenie',
  icon: AppIcons.add,
  variant: ButtonVariant.gradient,
  size: ButtonSize.large,
  onPressed: () {
    // Action
  },
)
```

**Użycie:**
- Akcje premium
- Wyróżnione oferty
- Konwersje biznesowe

### 3. Secondary Button
Alternatywny przycisk w ciemnym kolorze głównym (#181D24).

```dart
CustomButton(
  label: 'Więcej informacji',
  icon: AppIcons.info,
  variant: ButtonVariant.secondary,
  size: ButtonSize.medium,
  onPressed: () {
    // Action
  },
)
```

**Użycie:**
- Akcje drugorzędne
- Nawigacja
- Alternatywne wybory

### 4. Outlined Button
Przycisk z obramowaniem, subtelny akcent.

```dart
CustomButton(
  label: 'Zapisz do ulubionych',
  icon: AppIcons.favorites,
  variant: ButtonVariant.outlined,
  size: ButtonSize.medium,
  onPressed: () {
    // Action
  },
)
```

**Użycie:**
- Akcje opcjonalne
- Zapisywanie/udostępnianie
- Anulowanie

### 5. Text Button
Minimalny przycisk tekstowy.

```dart
CustomButton(
  label: 'Dowiedz się więcej',
  trailingIcon: Icons.arrow_forward_rounded,
  variant: ButtonVariant.text,
  size: ButtonSize.medium,
  onPressed: () {
    // Action
  },
)
```

**Użycie:**
- Linki tekstowe
- Akcje trzeciorzędne
- Nawigacja pomocnicza

## Rozmiary

```dart
// Mały
CustomButton(
  label: 'Zapisz',
  variant: ButtonVariant.primary,
  size: ButtonSize.small,
  onPressed: () {},
)

// Średni (domyślny)
CustomButton(
  label: 'Kontakt',
  variant: ButtonVariant.primary,
  size: ButtonSize.medium,
  onPressed: () {},
)

// Duży
CustomButton(
  label: 'Szukaj nieruchomości',
  variant: ButtonVariant.primary,
  size: ButtonSize.large,
  onPressed: () {},
)
```

## Ikony

### Leading Icon
```dart
CustomButton(
  label: 'Wyszukaj',
  icon: AppIcons.search,
  variant: ButtonVariant.primary,
  onPressed: () {},
)
```

### Trailing Icon
```dart
CustomButton(
  label: 'Dalej',
  trailingIcon: Icons.arrow_forward_rounded,
  variant: ButtonVariant.primary,
  onPressed: () {},
)
```

### Oba
```dart
CustomButton(
  label: 'Prześlij',
  icon: AppIcons.upload,
  trailingIcon: Icons.check_rounded,
  variant: ButtonVariant.primary,
  onPressed: () {},
)
```

## Stany

### Loading
```dart
CustomButton(
  label: 'Wysyłanie...',
  variant: ButtonVariant.primary,
  isLoading: true,
  onPressed: () {},
)
```

### Disabled
```dart
CustomButton(
  label: 'Wyłączony',
  variant: ButtonVariant.primary,
  onPressed: null, // null = disabled
)
```

### Full Width
```dart
CustomButton(
  label: 'Wyślij zapytanie',
  variant: ButtonVariant.primary,
  fullWidth: true,
  onPressed: () {},
)
```

## Tooltip

```dart
CustomButton(
  label: 'Info',
  icon: AppIcons.info,
  variant: ButtonVariant.outlined,
  tooltip: 'Kliknij aby zobaczyć szczegóły',
  onPressed: () {},
)
```

## Przykłady Użycia w Kontekście

### Hero Section - CTA
```dart
CustomButton(
  label: 'Szukaj nieruchomości komercyjnych',
  icon: AppIcons.search,
  trailingIcon: Icons.arrow_forward_rounded,
  variant: ButtonVariant.gradient,
  size: ButtonSize.large,
  onPressed: () => context.go(AppRouter.search),
)
```

### Formularz Kontaktowy
```dart
Column(
  children: [
    CustomButton(
      label: 'Wyślij zapytanie',
      icon: AppIcons.message,
      variant: ButtonVariant.primary,
      size: ButtonSize.large,
      fullWidth: true,
      isLoading: _isSubmitting,
      onPressed: _submitForm,
    ),
    const SizedBox(height: AppSpacing.md),
    CustomButton(
      label: 'Anuluj',
      variant: ButtonVariant.outlined,
      size: ButtonSize.large,
      fullWidth: true,
      onPressed: () => Navigator.pop(context),
    ),
  ],
)
```

### Karta Nieruchomości
```dart
Row(
  children: [
    Expanded(
      child: CustomButton(
        label: 'Kontakt',
        icon: AppIcons.phone,
        variant: ButtonVariant.primary,
        size: ButtonSize.medium,
        onPressed: _callOwner,
      ),
    ),
    const SizedBox(width: AppSpacing.sm),
    CustomButton(
      label: '',
      icon: AppIcons.favorites,
      variant: ButtonVariant.outlined,
      size: ButtonSize.medium,
      onPressed: _toggleFavorite,
    ),
    const SizedBox(width: AppSpacing.sm),
    CustomButton(
      label: '',
      icon: AppIcons.share,
      variant: ButtonVariant.outlined,
      size: ButtonSize.medium,
      onPressed: _share,
    ),
  ],
)
```

### Dashboard - Akcje
```dart
Row(
  children: [
    CustomButton(
      label: 'Dodaj nową ofertę',
      icon: AppIcons.add,
      variant: ButtonVariant.gradient,
      size: ButtonSize.large,
      onPressed: () => context.go(AppRouter.addListing),
    ),
    const SizedBox(width: AppSpacing.md),
    CustomButton(
      label: 'Statystyki',
      icon: AppIcons.statistics,
      variant: ButtonVariant.secondary,
      size: ButtonSize.large,
      onPressed: () => context.go(AppRouter.dashboardStatistics),
    ),
  ],
)
```

## Efekty Wizualne

### Geometryczne Dekoracje
Przyciski Primary i Gradient mają niestandardowe geometryczne dekoracje, które pojawiają się podczas hover:
- Trójkąty w rogach
- Przekątne linie
- Półprzezroczyste akcenty

Te efekty są inspirowane stylem hero section i tworzą spójny design system.

### Animacje
- **Scale animation**: Przycisk zmniejsza się lekko podczas kliknięcia (95%)
- **Hover effects**: Geometryczne elementy pojawiają się podczas hover
- **Shadow**: Dynamiczny cień przy hover
- **Transition**: Płynne przejścia 150-200ms

## Showcase

Aby zobaczyć wszystkie warianty przycisków:

```dart
// W przeglądarce:
http://localhost:PORT/#/showcase/buttons

// Lub w kodzie:
context.go(AppRouter.buttonShowcase);
```

## Best Practices

1. **Hierarchia wizualna**:
   - Primary/Gradient dla głównych akcji (1 na ekran)
   - Secondary dla akcji drugorzędnych
   - Outlined dla opcjonalnych
   - Text dla nawigacji

2. **Rozmiary**:
   - Large dla hero sections i głównych CTA
   - Medium dla formularzy i kart
   - Small dla inline akcji

3. **Ikony**:
   - Używaj ikon dla zwiększenia rozpoznawalności
   - Leading icon dla akcji (search, add, etc.)
   - Trailing icon dla nawigacji (arrows)

4. **Full Width**:
   - Używaj w formularzach mobilnych
   - W wąskich kolumnach
   - Dla spójności w kartach

5. **Loading**:
   - Zawsze pokazuj loading przy asynchronicznych akcjach
   - Wyłącz przycisk podczas loading

## Techniczne Szczegóły

### Parametry

| Parametr | Typ | Domyślnie | Opis |
|----------|-----|-----------|------|
| label | String | required | Tekst przycisku |
| onPressed | VoidCallback? | null | Callback po kliknięciu |
| icon | IconData? | null | Ikona po lewej |
| trailingIcon | IconData? | null | Ikona po prawej |
| variant | ButtonVariant | primary | Wariant stylu |
| size | ButtonSize | medium | Rozmiar |
| isLoading | bool | false | Stan loading |
| fullWidth | bool | false | Pełna szerokość |
| tooltip | String? | null | Tooltip |

### Custom Painter

`_GeometricButtonPainter` rysuje geometryczne dekoracje:
- Trójkąty w rogach (opacity 0.1)
- Przekątna linia (opacity 0.2)
- Aktywne tylko podczas hover
- Animowane przejścia

## Przykłady z Życia

Zobacz pełny showcase z wszystkimi wariantami i przykładami użycia:

```bash
flutter run -d chrome
# Przejdź do: /#/showcase/buttons
```

---

**Stworzone dla BC Agencja - Nieruchomości Komercyjne i Inwestycyjne**
