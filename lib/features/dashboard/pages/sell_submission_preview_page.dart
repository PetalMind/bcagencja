import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/listing_submission_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../features/sell_submission/sell_submission_page.dart';

/// Strona podglądu zgłoszenia do sprzedaży – ten sam formularz co przy dodawaniu, wypełniony danymi, tylko do odczytu.
/// Otwierana z panelu admina (Zgłoszenia do sprzedaży) z przekazanym [ListingSubmissionRecord] w [extra].
class SellSubmissionPreviewPage extends StatelessWidget {
  const SellSubmissionPreviewPage({super.key, required this.record});

  final dynamic record;

  @override
  Widget build(BuildContext context) {
    if (record == null || record is! ListingSubmissionRecord) {
      return Scaffold(
        appBar: AppBar(title: const Text('Błąd')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Brak danych zgłoszenia.'),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go(AppRouter.dashboardAdminSubmissions),
                child: const Text('Wróć do listy'),
              ),
            ],
          ),
        ),
      );
    }
    final r = record as ListingSubmissionRecord;
    final data = ListingSubmissionService.dataFromRecord(r);
    return SellSubmissionPage(
      initialData: data,
      readOnly: true,
    );
  }
}
