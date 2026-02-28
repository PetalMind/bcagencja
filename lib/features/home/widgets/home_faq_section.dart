import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
/// Sekcja FAQ na stronie głównej – rozwijane pytania i odpowiedzi.
class HomeFaqSection extends StatelessWidget {
  const HomeFaqSection({super.key});

  static const List<_FaqItem> _items = [
    _FaqItem(
      question: 'Czym jest nieruchomość komercyjna?',
      answer:
          'Nieruchomość komercyjna to obiekt lub grunt wykorzystywany do działalności gospodarczej, a nie do celów mieszkalnych. Obejmuje m.in. biura, magazyny, hale, lokale handlowe, hotele oraz działki inwestycyjne. W ofercie BC Agencja znajdziesz obiekty na sprzedaż i do wynajęcia, z pełnymi danymi technicznymi i informacjami o rentowności.',
    ),
    _FaqItem(
      question: 'Jak wycenić nieruchomość komercyjną?',
      answer:
          'Wycena zależy od wielu czynników: lokalizacji, stanu obiektu, rodzaju najemców, długości umów najmu, stopy zwrotu w okolicy oraz trendów na rynku. BC Agencja oferuje bezpłatną wycenę w 48 godzin – skorzystaj z formularza „Chcę sprzedać” po zalogowaniu i weryfikacji konta.',
    ),
    _FaqItem(
      question: 'Co to jest stopa zwrotu (ROI) i jak ją obliczyć?',
      answer:
          'Stopa zwrotu (ROI) to stosunek rocznego dochodu z nieruchomości (np. czynszu) do ceny zakupu, wyrażony w procentach. Im wyższa stopa, tym szybszy zwrot z inwestycji. W naszym Kalkulatorze ROI możesz wpisać cenę, koszty, przychody i leverage – narzędzie pokaże stopę zwrotu oraz oferty o podobnych parametrach.',
    ),
    _FaqItem(
      question: 'Jak wygląda proces zakupu przez BC Agencja?',
      answer:
          'Jako inwestor przeglądasz oferty (teasery) na portalu. Po zalogowaniu (LinkedIn lub NIP) możesz zgłosić zainteresowanie konkretną ofertą. Dalszy krok to podpisanie NDA i uzyskanie dostępu do pełnych danych oraz wirtualnego data roomu (VDR) z dokumentacją. Transakcję koordynuje nasz zespół.',
    ),
    _FaqItem(
      question: 'Czy mogę sprzedać nieruchomość z zachowaniem poufności?',
      answer:
          'Tak. Dyskrecja jest dla nas priorytetem. Oferty są prezentowane inwestorom po weryfikacji tożsamości i podpisaniu NDA. Dane wrażliwe (adres, dokładna cena, dokumenty) są udostępniane wyłącznie w zabezpieczonym VDR. Możesz też skorzystać z bezpłatnej wyceny w 48h – bez zobowiązań.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: isMobile ? AppSpacing.lg : AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Najczęściej zadawane pytania',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              ..._items.map((item) => _FaqTile(item: item)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.item});

  final _FaqItem item;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.question,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.item.answer,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
