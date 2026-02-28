import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/mobile_menu.dart';

/// Pełna treść Umowy o Zachowaniu Poufności (NDA) BC Agencja.
const String ndaPageContent = '''
UMOWA O ZACHOWANIU POUFNOŚCI (NDA)
BC Agencja Nieruchomości / BCOSMOPOLITAN SPÓŁKA AKCYJNA

STRONY UMOWY
Udostępniający: BC Agencja Nieruchomości / BCOSMOPOLITAN S.A., wpisana do rejestru przedsiębiorców KRS, adres siedziby: (uzupełnić)
Odbiorca: Użytkownik platformy, który zaakceptował niniejszą umowę w aplikacji mobilnej BC Agencja.

PREAMBUŁA
Niniejsza Umowa o Zachowaniu Poufności („Umowa") zostaje zawarta w związku z udostępnieniem Odbiorcy dostępu do niepublicznych ofert nieruchomości, materiałów inwestycyjnych oraz informacji handlowych BC Agencja za pośrednictwem platformy cyfrowej. Celem Umowy jest ochrona uzasadnionych interesów biznesowych Udostępniającego przy jednoczesnym umożliwieniu Odbiorcy korzystania z platformy.

1. DEFINICJE
1.1 Informacje Poufne oznaczają wszelkie dane, dokumenty i materiały udostępnione Odbiorcy za pośrednictwem platformy, w szczególności:

• niepubliczne oferty nieruchomości i ich lokalizacje
• wyceny, opisy techniczne i dokumentację nieruchomości
• warunki transakcji, ceny ofertowe i negocjacyjne
• dane właścicieli i sprzedających nieruchomości
• strategie sprzedażowe i materiały marketingowe BC Agencja

1.2 Wyłączenia – za Informacje Poufne nie uznaje się danych, które:

• są powszechnie dostępne publicznie bez naruszenia niniejszej Umowy
• Odbiorca posiadał przed uzyskaniem dostępu do platformy
• Odbiorca otrzymał legalnie od osoby trzeciej uprawnionej do ich ujawnienia
• musi ujawnić na podstawie obowiązującego prawa lub nakazu sądu


2. ZOBOWIĄZANIA ODBIORCY
Odbiorca zobowiązuje się do:
2.1 Wykorzystywania Informacji Poufnych wyłącznie w celu oceny i realizacji transakcji nieruchomościowych za pośrednictwem platformy BC Agencja.
2.2 Nieujawniania Informacji Poufnych osobom trzecim bez uprzedniej pisemnej zgody Udostępniającego.
2.3 Niekopiowania, niedrukowania ani nierozpowszechniania materiałów udostępnionych w platformie w jakiejkolwiek formie.
2.4 Niezwłocznego powiadomienia BC Agencja w przypadku nieuprawnionego ujawnienia lub podejrzenia wycieku Informacji Poufnych.
2.5 Stosowania co najmniej takich samych środków ochrony, jakich Odbiorca używa do zabezpieczenia własnych informacji poufnych, nie mniejszych niż należyta staranność.

3. OKRES OBOWIĄZYWANIA
3.1 Umowa obowiązuje przez czas korzystania z platformy oraz przez 3 (trzy) lata po usunięciu konta lub zakończeniu współpracy.
3.2 Zobowiązania dotyczące danych osobowych właścicieli nieruchomości obowiązują bezterminowo lub do czasu ich upublicznienia.

4. NARUSZENIE UMOWY I ODPOWIEDZIALNOŚĆ
4.1 W przypadku naruszenia Umowy Odbiorca zobowiązany jest do zapłaty kary umownej w wysokości 50 000 PLN (pięćdziesiąt tysięcy złotych) za każde stwierdzone naruszenie.
4.2 BC Agencja zastrzega sobie prawo dochodzenia odszkodowania przewyższającego wysokość kary umownej na zasadach ogólnych Kodeksu Cywilnego.
4.3 Naruszenie Umowy stanowi podstawę do natychmiastowego zablokowania dostępu do platformy.
4.4 BC Agencja może dochodzić roszczeń w trybie zabezpieczenia sądowego (zakaz tymczasowy) bez konieczności wykazania szkody majątkowej.

5. DANE OSOBOWE
5.1 Dane osobowe udostępniane w ramach platformy (dane właścicieli, sprzedających) podlegają ochronie zgodnie z RODO.
5.2 Odbiorca jest uprawniony do przetwarzania tych danych wyłącznie w celu realizacji transakcji i zobowiązuje się do ich usunięcia po zakończeniu procesu.

6. POSTANOWIENIA KOŃCOWE
6.1 Umowa podlega prawu polskiemu.
6.2 Spory wynikające z Umowy rozstrzygane będą przez sąd właściwy dla siedziby BC Agencja.
6.3 Nieważność któregokolwiek postanowienia Umowy nie wpływa na ważność pozostałych.
6.4 Umowa wchodzi w życie z chwilą kliknięcia przycisku „Akceptuję" w aplikacji, co jest równoznaczne ze złożeniem oświadczenia woli w formie elektronicznej zgodnie z art. 60 KC.

Akceptując niniejszą Umowę potwierdzasz, że zapoznałeś się z jej treścią, rozumiesz jej postanowienia i zobowiązujesz się do ich przestrzegania.
''';

/// Strona z pełną treścią Umowy o Zachowaniu Poufności (NDA).
class NdaPage extends StatelessWidget {
  const NdaPage({super.key});

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
                  'Umowa o Zachowaniu Poufności (NDA)',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'BC Agencja Nieruchomości / BCOSMOPOLITAN S.A.',
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
                    ndaPageContent.trim(),
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
