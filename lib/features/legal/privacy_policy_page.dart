import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/mobile_menu.dart';

/// Pełna treść Polityki Prywatności BC Agencja.
const String privacyPolicyContent = '''
POLITYKA PRYWATNOŚCI

BC Agencja Nieruchomości
Data obowiązywania: 28.02.2026


1. Administrator danych osobowych

Administratorem danych osobowych użytkowników aplikacji mobilnej BC Agencja jest BC Agencja Nieruchomości, prowadząca działalność pod adresem internetowym https://bcagencja.eu (dalej: „Administrator").

W sprawach dotyczących ochrony danych osobowych można kontaktować się za pośrednictwem formularza kontaktowego dostępnego na stronie bcagencja.eu.


2. Jakie dane zbieramy

W ramach korzystania z aplikacji zbieramy następujące dane osobowe:

• Imię i nazwisko – w celu identyfikacji użytkownika
• Adres e-mail – podany podczas rejestracji lub logowania za pomocą konta Google
• Numer telefonu – w celu umożliwienia kontaktu w sprawach nieruchomości


3. W jakim celu przetwarzamy dane

Dane osobowe przetwarzane są w następujących celach:

• Świadczenie usług za pośrednictwem aplikacji mobilnej (art. 6 ust. 1 lit. b RODO)
• Umożliwienie logowania i uwierzytelniania użytkownika
• Kontakt z użytkownikiem w sprawach dotyczących ofert nieruchomości
• Wysyłanie powiadomień związanych z aktywnością w aplikacji
• Spełnienie obowiązków prawnych ciążących na Administratorze (art. 6 ust. 1 lit. c RODO)


4. Podstawa prawna przetwarzania

Przetwarzamy Twoje dane na podstawie:

• Zgody użytkownika – przy logowaniu przez Google i podaniu numeru telefonu
• Niezbędności do wykonania umowy – świadczenie usług aplikacji
• Prawnie uzasadnionego interesu Administratora – poprawa jakości usług i bezpieczeństwo aplikacji


5. Logowanie przez Google (Firebase)

Aplikacja korzysta z usługi Firebase Authentication firmy Google LLC w celu umożliwienia logowania przez konto Google. Oznacza to, że część danych (adres e-mail, imię i nazwisko, zdjęcie profilowe) może być przekazana do serwerów Google zgodnie z polityką prywatności Google dostępną pod adresem: https://policies.google.com/privacy

Firebase przetwarza dane zgodnie ze standardami bezpieczeństwa i może przechowywać dane na serwerach zlokalizowanych poza Europejskim Obszarem Gospodarczym, przy zachowaniu odpowiednich zabezpieczeń.


6. Komu przekazujemy dane

Dane osobowe mogą być przekazywane:

• Google LLC – w ramach usługi Firebase Authentication i infrastruktury chmurowej
• Podwykonawcom Administratora – jedynie w zakresie niezbędnym do świadczenia usług, na podstawie umów powierzenia przetwarzania danych
• Organom państwowym – wyłącznie na podstawie obowiązujących przepisów prawa

Nie sprzedajemy danych osobowych użytkowników osobom trzecim.


7. Jak długo przechowujemy dane

Dane osobowe przechowujemy przez okres:

• Trwania konta użytkownika w aplikacji
• Do czasu wycofania zgody – w przypadku danych przetwarzanych na jej podstawie
• Wymagany przez przepisy prawa – w zakresie danych, do przechowywania których jesteśmy zobowiązani

Po usunięciu konta dane są trwale usuwane w ciągu 30 dni.


8. Prawa użytkownika

Każdemu użytkownikowi przysługują następujące prawa:

• Prawo dostępu do swoich danych osobowych
• Prawo do sprostowania nieprawidłowych danych
• Prawo do usunięcia danych („prawo do bycia zapomnianym")
• Prawo do ograniczenia przetwarzania danych
• Prawo do przenoszenia danych
• Prawo do wycofania zgody w dowolnym momencie, bez wpływu na zgodność z prawem przetwarzania dokonanego przed jej wycofaniem
• Prawo do wniesienia skargi do Prezesa Urzędu Ochrony Danych Osobowych (UODO), ul. Stawki 2, 00-193 Warszawa


9. Bezpieczeństwo danych

Stosujemy odpowiednie środki techniczne i organizacyjne w celu ochrony danych osobowych przed nieuprawnionym dostępem, utratą lub zniszczeniem. Dane przesyłane są z użyciem szyfrowanego połączenia (HTTPS/SSL).


10. Zmiany polityki prywatności

Administrator zastrzega sobie prawo do wprowadzania zmian w niniejszej Polityce Prywatności. O wszelkich istotnych zmianach użytkownicy zostaną poinformowani za pośrednictwem aplikacji lub wiadomości e-mail. Aktualna wersja Polityki Prywatności jest zawsze dostępna w aplikacji oraz na stronie bcagencja.eu.


Niniejsza Polityka Prywatności została sporządzona zgodnie z Rozporządzeniem Parlamentu Europejskiego i Rady (UE) 2016/679 z dnia 27 kwietnia 2016 r. (RODO).
''';

/// Strona z pełną treścią Polityki Prywatności.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    return Scaffold(
      appBar: const AppBarCustom(showBackButton: true),
      drawer: isMobile ? const MobileMenu() : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Polityka Prywatności',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'BC Agencja Nieruchomości • Data obowiązywania: 28.02.2026',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: SelectableText(
                    privacyPolicyContent.trim(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Wróć'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
