# System ról w portalu BC Agencja

**Wersja:** 1.0  
**Data:** 17.02.2026

## Role i poziomy

| Poziom | Rola | Opis | Warunek |
|--------|------|------|---------|
| 0 | **GUEST** (Gość) | Niezalogowany użytkownik | Brak sesji |
| 1 | **INVESTOR_BASIC** | Inwestor podstawowy | Rejestracja bez NDA |
| 2 | **INVESTOR_VERIFIED** | Inwestor zweryfikowany | Rejestracja + akceptacja NDA |
| 3 | **INVESTOR_VIP** | Inwestor VIP | Zweryfikowany + VDR per oferta |
| 4 | **AGENT** | Agent nieruchomości | Zaproszenie + przypisanie do województwa |
| 5 | **DIRECTOR** | Dyrektor obszaru | Zaproszenie + nadzór regionu |
| 6 | **ADMIN** | Administrator | Pełny dostęp |
| — | **SELLER_LEAD** | Potencjalny sprzedający | Formularz „Chcę sprzedać” – **nie konto użytkownika** |

## Uprawnienia

### GUEST (Level 0)
- ✅ Strona główna, kalkulator ROI, teasery ofert, formularz „Chcę sprzedać”
- ❌ Pełne oferty, zapis kalkulacji, watchlist
- **CTA:** Kliknięcie w ofertę → modal „Zaloguj się, aby zobaczyć więcej”

### INVESTOR_BASIC (Level 1)
- ✅ Wszystko co Guest + zapis kalkulacji, watchlist, edycja profilu
- ❌ Pełne oferty (wymaga NDA)
- **Banner:** „Zaakceptuj NDA, aby odblokować pełne oferty”
- **CTA:** Kliknięcie w ofertę → modal „Zaakceptuj NDA”

### INVESTOR_VERIFIED (Level 2)
- ✅ Wszystko co Level 1 + pełne oferty, kontakt z agentem, dokumenty podstawowe (PDF z watermarkiem)
- ❌ VDR (umowy najmu, operaty, dokumenty prawne)
- **CTA:** „Poproś o dostęp do VDR” (Proof of Funds)

### INVESTOR_VIP (Level 3)
- ✅ Wszystko co Level 2 + VDR per oferta, dokumenty prawne, priorytetowy kontakt
- Dostęp VDR jest **per-oferta** – weryfikacja PoF dla każdej nieruchomości

### AGENT (Level 4)
- ✅ Panel Agenta, dodawanie ofert (draft → pending review), edycja własnych, upload dokumentacji
- ❌ Publikacja bez akceptacji Dyrektora, oferty innych agentów (oprócz regionu)

### DIRECTOR (Level 5)
- ✅ Wszystko co Agent + dashboard regionalny, akceptacja ofert, zarządzanie VDR, statystyki regionu
- ❌ Inne województwa, tworzenie użytkowników

### ADMIN (Level 6)
- ✅ Pełny dostęp: użytkownicy, content, logi, zgłoszenia „Chcę sprzedać”, ustawienia globalne

## Implementacja techniczna

- **`lib/core/auth/role_permissions.dart`** – enum `UserRoleLevel`, klasa `RolePermissions`
- **`lib/core/auth/app_user.dart`** – `effectiveRoleLevel`, gettery uprawnień
- **`lib/core/router/app_router.dart`** – redirecty: guest → login, inwestor → blokada add-listing
- **`lib/widgets/common/login_required_modal.dart`** – modal dla GUEST
- **`lib/widgets/common/nda_required_modal.dart`** – modal dla INVESTOR_BASIC
- **Firestore `users`** – `role` (lead/agent/director/admin), `ndaAcceptedAt`, `vdrAccessForListingIds`

## Mapowanie Firestore → effectiveRoleLevel

| Firestore `role` | `ndaAcceptedAt` | `vdrAccessForListingIds` | effectiveRoleLevel |
|------------------|-----------------|--------------------------|--------------------|
| — (null)         | —               | —                        | GUEST              |
| lead             | null            | —                        | INVESTOR_BASIC     |
| lead             | set             | []                       | INVESTOR_VERIFIED  |
| lead             | set             | [id, …]                  | INVESTOR_VIP       |
| agent            | —               | —                        | AGENT              |
| director         | —               | —                        | DIRECTOR           |
| admin            | —               | —                        | ADMIN              |
