import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';

/// Mapowanie pageId (z URL) na tytuł i opis prototypu.
Map<String, ({String title, String subtitle})> get adminPanelPlaceholders {
  return {
    'overview': (title: 'Przegląd całego systemu', subtitle: 'Dashboard globalny – wszystkie województwa i kluczowe KPI.'),
    'regions-map': (title: 'Wszystkie województwa', subtitle: 'Mapa i lista regionów z podsumowaniem.'),
    'metrics': (title: 'Metryki biznesowe', subtitle: 'KPI, konwersje, pipeline.'),
    'alerts': (title: 'Alerty systemowe', subtitle: 'Ostrzeżenia, błędy, wymagane akcje.'),
    'regions-list': (title: 'Lista województw', subtitle: 'Zarządzanie regionami – lista województw.'),
    'regions-edit': (title: 'Dodaj / edytuj województwo', subtitle: 'Formularz konfiguracji regionu.'),
    'regions-directors': (title: 'Przypisz Dyrektorów', subtitle: 'Przypisywanie Dyrektorów do województw.'),
    'regions-stats': (title: 'Statystyki regionalne', subtitle: 'Metryki i raporty wg regionów.'),
    'users-roles': (title: 'Użytkownicy według ról', subtitle: 'Filtrowanie i zarządzanie wg ról.'),
    'users-verifications': (title: 'Weryfikacje tożsamości', subtitle: 'Status weryfikacji, NDA, Proof of Funds.'),
    'users-activity': (title: 'Logi aktywności', subtitle: 'Historia logowań i akcji użytkowników.'),
    'users-access': (title: 'Zarządzanie dostępami', subtitle: 'Uprawnienia, blokady, wygaśnięcie dostępu.'),
    'listings-global': (title: 'Globalna lista nieruchomości', subtitle: 'Wszystkie oferty w systemie.'),
    'listings-quality': (title: 'Kontrola jakości', subtitle: 'Audyt treści i dokumentów ofert.'),
    'listings-moderation': (title: 'Moderacja', subtitle: 'Oferty do zatwierdzenia lub odrzucenia.'),
    'listings-archive': (title: 'Archiwizacja', subtitle: 'Zarchiwizowane oferty.'),
    'vdr-documents': (title: 'Wszystkie dokumenty VDR', subtitle: 'Centralna lista dokumentów w Virtual Data Room.'),
    'vdr-watermarks': (title: 'Logi watermarków', subtitle: 'Historia generowania i pobrań z watermarkiem.'),
    'vdr-violations': (title: 'Naruszenia (potencjalne wycieki)', subtitle: 'Wykryte naruszenia polityki VDR.'),
    'vdr-permissions': (title: 'Zarządzanie uprawnieniami VDR', subtitle: 'Dostęp użytkowników do dokumentów.'),
    'security-logs': (title: 'Logi bezpieczeństwa', subtitle: 'Zdarzenia bezpieczeństwa systemu.'),
    'security-nda': (title: 'NDA tracking', subtitle: 'Status NDA, daty akceptacji.'),
    'security-ip': (title: 'IP blacklist', subtitle: 'Zablokowane adresy IP.'),
    'security-unauthorized': (title: 'Próby nieuprawnionego dostępu', subtitle: 'Nieudane logowania i podejrzane aktywności.'),
    'reports-bi': (title: 'Dashboard BI', subtitle: 'Raporty biznesowe i wizualizacje.'),
    'reports-financial': (title: 'Raporty finansowe (REIT)', subtitle: 'Przygotowanie danych pod REIT.'),
    'reports-conversion': (title: 'Analiza konwersji', subtitle: 'Ścieżki konwersji i lejki.'),
    'reports-journey': (title: 'User journey analytics', subtitle: 'Analiza ścieżek użytkowników.'),
    'reports-ab': (title: 'A/B testing', subtitle: 'Eksperymenty i warianty.'),
    'config-global': (title: 'Ustawienia globalne', subtitle: 'Ogólna konfiguracja systemu.'),
    'config-roles': (title: 'Zarządzanie rolami', subtitle: 'Definicje ról i uprawnień.'),
    'config-workflow': (title: 'Workflow i procesy', subtitle: 'Procesy zatwierdzania i automatyzacje.'),
    'config-integrations': (title: 'Integracje (LinkedIn OAuth, NIP API)', subtitle: 'Połączenia z zewnętrznymi serwisami.'),
    'config-templates': (title: 'Szablony email / powiadomień', subtitle: 'Treści wiadomości i powiadomień.'),
    'config-watermarking': (title: 'Parametry watermarkingu', subtitle: 'Ustawienia znaków wodnych w dokumentach.'),
    'dev-logs': (title: 'Logi systemowe', subtitle: 'Logi aplikacji i serwisów.'),
    'dev-api': (title: 'Status API', subtitle: 'Stan endpointów i zależności.'),
    'dev-backup': (title: 'Backup & restore', subtitle: 'Kopie zapasowe i przywracanie.'),
    'dev-migrations': (title: 'Migracje bazy', subtitle: 'Skrypty i historia migracji.'),
    'submissions-workflow': (title: 'Workflow procesowania', subtitle: 'Etapy obsługi zgłoszeń „Chcę sprzedać”.'),
    'submissions-regions': (title: 'Przypisanie do regionów', subtitle: 'Przypisywanie leadów do województw i Dyrektorów.'),
  };
}

/// Prosta strona prototypu dla podstron panelu Super Admin.
/// Wyświetla tytuł i opis na podstawie [pageId] z ścieżki.
class AdminPlaceholderPage extends StatelessWidget {
  const AdminPlaceholderPage({
    super.key,
    required this.pageId,
  });

  final String pageId;

  @override
  Widget build(BuildContext context) {
    final placeholders = adminPanelPlaceholders;
    final data = placeholders[pageId];
    final title = data?.title ?? 'Panel administracyjny';
    final subtitle = data?.subtitle ?? 'Strona w budowie.';

    return DashboardScaffold(
      title: title,
      currentRoute: '${AppRouter.dashboard}/admin/panel/$pageId',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Icon(Icons.construction_outlined, size: 40, color: AppColors.accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Prototyp – funkcjonalność zostanie zaimplementowana w kolejnych iteracjach.',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRouter.dashboard),
            icon: const Icon(Icons.dashboard),
            label: const Text('Wróć do Dashboard'),
          ),
        ],
      ),
    );
  }
}
