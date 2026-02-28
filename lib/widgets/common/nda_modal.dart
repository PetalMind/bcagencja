import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';

/// Skrócona treść NDA do wyświetlenia w modalu. Pełna wersja na stronie /umowa-nda.
const String ndaContentText = '''
UMOWA O ZACHOWANIU POUFNOŚCI (NDA)
BC Agencja Nieruchomości / BCOSMOPOLITAN S.A.

Udostępniający udziela Odbiorcy dostępu do niepublicznych ofert nieruchomości i materiałów inwestycyjnych za pośrednictwem platformy BC Agencja.

1. Informacje Poufne – to m.in. niepubliczne oferty i lokalizacje, wyceny, opisy techniczne, warunki transakcji, ceny, dane właścicieli oraz materiały marketingowe BC Agencja.

2. Zobowiązania Odbiorcy: wykorzystywanie Informacji Poufnych wyłącznie do oceny i realizacji transakcji za pośrednictwem platformy; nieujawnianie osobom trzecim bez pisemnej zgody; niekopiowanie i nierozpowszechnianie materiałów; niezwłoczne powiadomienie BC Agencja w razie wycieku; stosowanie należytej staranności przy ochronie danych.

3. Okres obowiązywania: czas korzystania z platformy oraz 3 lata po usunięciu konta. Zobowiązania co do danych osobowych właścicieli – bezterminowo.

4. Naruszenie Umowy: kara umowna 50 000 PLN za każde naruszenie; BC Agencja może dochodzić wyższego odszkodowania; możliwe zablokowanie dostępu i zabezpieczenie sądowe.

5. Umowa podlega prawu polskiemu i wchodzi w życie z chwilą kliknięcia „Akceptuję" w aplikacji (art. 60 KC).

Pełna treść umowy dostępna na stronie „Umowa NDA" w aplikacji.
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
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(AppRouter.umowaNda);
                      },
                      child: Text(
                        'Przeczytaj pełną umowę NDA',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.accent,
                          decoration: TextDecoration.underline,
                        ),
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
