import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Treść NDA (skrócona, 300–500 słów). W produkcji ładować z CMS lub pliku.
const String ndaContentText = '''
UMOWA O POUFNOŚCI (NDA)

Niniejsza umowa określa warunki udostępniania poufnych informacji dotyczących ofert nieruchomości przez BC Agencja („Udostępniający”) użytkownikowi platformy („Odbiorca”).

1. Definicja informacji poufnych
Informacjami poufnymi są wszelkie dane, dokumenty, lokalizacje, opisy, wyceny i materiały dotyczące ofert nieruchomości udostępniane w ramach platformy, z wyłączeniem informacji publicznie dostępnych.

2. Zobowiązania Odbiorcy
Odbiorca zobowiązuje się: (a) wykorzystywać informacje poufne wyłącznie do własnej oceny inwestycyjnej; (b) nie ujawniać ich osobom trzecim bez pisemnej zgody Udostępniającego; (c) nie kopiować ani nie rozpowszechniać materiałów bez zgody; (d) zabezpieczyć dane przed nieuprawnionym dostępem.

3. Dane są chronione prawnie. Naruszenie obowiązków może skutkować odpowiedzialnością cywilną i karną.

4. Kara umowna za naruszenie niniejszej umowy wynosi 50 000 PLN (pięćdziesiąt tysięcy złotych) za każde naruszenie, bez uszczerbku dla roszczeń o naprawienie szkody.

5. Umowa wchodzi w życie z chwilą zaakceptowania przez Odbiorcę. Udostępniający zastrzega prawo do weryfikacji tożsamości Odbiorcy.

Kontakt: BC Agencja.
''';

/// Modal z pełnym tekstem NDA, scrollowaniem i śledzeniem czy użytkownik przewinął do końca.
/// Zwraca (accepted, scrolledToEnd) przez callback [onAccept] lub null przy anulowaniu.
class NdaModal extends StatefulWidget {
  const NdaModal({
    super.key,
    this.onAccept,
    this.pdfUrl,
  });

  /// Wywołane z (accepted, scrolledToEnd) gdy użytkownik kliknie Akceptuję.
  final void Function(bool accepted, bool scrolledToEnd)? onAccept;
  /// Opcjonalny link do pobrania PDF NDA.
  final String? pdfUrl;

  static Future<({bool accepted, bool scrolledToEnd})?> show(
    BuildContext context, {
    String? pdfUrl,
  }) async {
    ({bool accepted, bool scrolledToEnd})? result;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NdaModal(
        pdfUrl: pdfUrl,
        onAccept: (accepted, scrolledToEnd) {
          result = (accepted: accepted, scrolledToEnd: scrolledToEnd);
          Navigator.of(context).pop();
        },
      ),
    );
    return result;
  }

  @override
  State<NdaModal> createState() => _NdaModalState();
}

class _NdaModalState extends State<NdaModal> {
  final ScrollController _scrollController = ScrollController();
  bool _scrolledToEnd = false;
  bool _checkboxAccepted = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollToEnd);
  }

  void _checkScrollToEnd() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (!_scrolledToEnd && maxScroll > 0 && current >= maxScroll - 24) {
      setState(() => _scrolledToEnd = true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollToEnd);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Umowa o Poufności (NDA)',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ndaContentText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _checkboxAccepted,
                            onChanged: (v) =>
                                setState(() => _checkboxAccepted = v ?? false),
                            activeColor: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Przeczytałem/am i akceptuję warunki NDA (wymagane)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (widget.pdfUrl != null) ...[
                    TextButton.icon(
                      onPressed: () {
                        // url_launcher could be used here
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Pobierz PDF'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Anuluj'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _checkboxAccepted
                        ? () => widget.onAccept?.call(
                            _checkboxAccepted, _scrolledToEnd)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                    ),
                    child: const Text('Akceptuję'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
