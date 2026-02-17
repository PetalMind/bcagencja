import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/role_permissions.dart';
import '../state/providers/auth_provider.dart';
import '../../features/home/home_page.dart';
import '../../features/search/search_page.dart';
import '../../features/listings/listings_results_page.dart';
import '../../features/property/property_detail_page.dart';
import '../../features/add_listing/add_listing_page.dart';
import '../../features/add_listing/add_listing_success_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/dashboard/pages/my_listings_page.dart';
import '../../features/dashboard/pages/favorites_page.dart';
import '../../features/dashboard/pages/alerts_page.dart';
import '../../features/dashboard/pages/messages_page.dart';
import '../../features/dashboard/pages/statistics_page.dart';
import '../../features/dashboard/pages/settings_page.dart';
import '../../features/dashboard/pages/admin_users_page.dart';
import '../../features/dashboard/pages/admin_submissions_page.dart';
import '../../features/dashboard/pages/admin_logs_page.dart';
import '../../features/about/about_page.dart';
import '../../features/blog/blog_page.dart';
import '../../features/contact/contact_page.dart';
import '../../features/roi_calculator/roi_calculator_page.dart';
import '../../features/login/login_page.dart';
import '../../features/registration/registration_page.dart';
import '../../features/registration/complete_oauth_registration_page.dart';
import '../../features/registration/nip_registration_page.dart';
import '../../features/registration/invite_registration_page.dart';
import '../../features/verify_account/verify_account_page.dart';
import '../../features/sell_submission/sell_submission_page.dart';
import '../../features/sell_submission/sell_submission_success_page.dart';
import '../../widgets/common/button_showcase.dart';

/// Application router configuration
class AppRouter {
  // Route names
  static const String home = '/';
  static const String oferty = '/oferty';
  static const String kalkulatorRoi = '/kalkulator-roi';
  static const String chceSprzedac = '/chce-sprzedac';
  static const String logowanie = '/logowanie';
  static const String rejestracja = '/rejestracja';
  static const String rejestracjaDokoncz = '/rejestracja/dokoncz';
  static const String rejestracjaNip = '/rejestracja/nip';
  static const String zaproszenie = '/zaproszenie';
  static const String weryfikacja = '/weryfikacja';
  static const String search = '/search';
  static const String searchResults = '/search/results';
  static const String propertyDetail = '/property/:id';
  static const String addListing = '/add-listing';
  static const String addListingSuccess = '/add-listing/success';
  static const String dashboard = '/dashboard';
  static const String dashboardListings = '/dashboard/listings';
  static const String dashboardFavorites = '/dashboard/favorites';
  static const String dashboardAlerts = '/dashboard/alerts';
  static const String dashboardMessages = '/dashboard/messages';
  static const String dashboardStatistics = '/dashboard/statistics';
  static const String dashboardSettings = '/dashboard/settings';
  static const String dashboardAdminUsers = '/dashboard/admin/users';
  static const String dashboardAdminSubmissions = '/dashboard/admin/submissions';
  static const String dashboardAdminLogs = '/dashboard/admin/logs';
  // Dodatkowe dla sidebar (Investor L2/L3, Agent, Director, Admin)
  static const String dashboardProfile = '/dashboard/profile';
  static const String dashboardDocuments = '/dashboard/documents';
  static const String dashboardVdr = '/dashboard/vdr';
  static const String dashboardRoiHistory = '/dashboard/roi-history';
  static const String about = '/about';
  static const String blog = '/blog';
  static const String contact = '/contact';
  static const String buttonShowcase = '/showcase/buttons';

  /// Wywołaj notifyListeners() gdy stan auth się zmienia – router przeładuje redirect.
  static final ValueNotifier<int> authRefreshNotifier = ValueNotifier(0);

  /// Router configuration
  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,
    refreshListenable: authRefreshNotifier,
    redirect: (context, state) {
      try {
        final container = ProviderScope.containerOf(context);
        final user = container.read(currentUserProvider).valueOrNull;
        final loc = state.matchedLocation;
        final roleLevel = user?.effectiveRoleLevel ?? UserRoleLevel.guest;

        // Zalogowany na stronie logowania → przekieruj do dashboard
        if (user != null &&
            (loc == logowanie || loc.startsWith('$logowanie/'))) {
          final returnTo = state.uri.queryParameters['returnTo'];
          return returnTo != null && returnTo.isNotEmpty
              ? returnTo
              : dashboard;
        }

        // Niezalogowany na dashboard / add-listing → przekieruj do logowania
        if (user == null) {
          if (loc == dashboard || loc.startsWith('$dashboard/') ||
              loc == addListing || loc.startsWith('$addListing')) {
            return '$logowanie?returnTo=${Uri.encodeComponent(loc)}';
          }
        }

        // Inwestor (nie Agent/Dyrektor/Admin) na add-listing → brak dostępu
        if (!RolePermissions.canAddListings(roleLevel) &&
            (loc == addListing || loc.startsWith('$addListing/'))) {
          return dashboard;
        }

        // Panel admina: tylko ADMIN
        if (!RolePermissions.hasAdminDashboard(roleLevel) &&
            (loc.contains('/admin/users') ||
                loc.contains('/admin/submissions') ||
                loc.contains('/admin/logs'))) {
          return dashboard;
        }
      } catch (_) {}
      return null;
    },
    routes: [
      // Home page
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      // Baza ofert (teasery) – główny punkt wejścia dla inwestorów
      GoRoute(
        path: oferty,
        name: 'oferty',
        builder: (context, state) => const ListingsResultsPage(),
      ),
      // Kalkulator ROI – publiczne narzędzie
      GoRoute(
        path: kalkulatorRoi,
        name: 'kalkulatorRoi',
        builder: (context, state) => const RoiCalculatorPage(),
      ),
      // Chcę sprzedać – lead magnet (formularz zgłoszenia → listing_submissions, status: pending)
      GoRoute(
        path: chceSprzedac,
        name: 'chceSprzedac',
        builder: (context, state) => const SellSubmissionPage(),
        routes: [
          GoRoute(
            path: 'sukces',
            name: 'chceSprzedacSuccess',
            builder: (context, state) => const SellSubmissionSuccessPage(),
          ),
        ],
      ),
      // Logowanie (Google / Apple / Email) – returnTo: ścieżka po zalogowaniu
      GoRoute(
        path: logowanie,
        name: 'logowanie',
        builder: (context, state) => LoginPage(
          returnTo: state.uri.queryParameters['returnTo'],
        ),
      ),
      // Rejestracja – wybór OAuth lub NIP
      GoRoute(
        path: rejestracja,
        name: 'rejestracja',
        builder: (context, state) => const RegistrationPage(),
        routes: [
          // Dokończ rejestrację po OAuth (osoba/firma, NDA)
          GoRoute(
            path: 'dokoncz',
            name: 'rejestracjaDokoncz',
            builder: (context, state) => CompleteOAuthRegistrationPage(
              returnTo: state.uri.queryParameters['returnTo'],
            ),
          ),
          // Rejestracja firmowa przez NIP
          GoRoute(
            path: 'nip',
            name: 'rejestracjaNip',
            builder: (context, state) => const NipRegistrationPage(),
          ),
        ],
      ),
      // Zaproszenie Agent/Dyrektor – token w query
      GoRoute(
        path: zaproszenie,
        name: 'zaproszenie',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return InviteRegistrationPage(token: token);
        },
      ),
      // Weryfikacja konta (Level 2 – NIP + NDA dla użytkowników bez OAuth)
      GoRoute(
        path: weryfikacja,
        name: 'weryfikacja',
        builder: (context, state) => VerifyAccountPage(
          returnTo: state.uri.queryParameters['returnTo'],
        ),
      ),
      // Search page
      GoRoute(
        path: search,
        name: 'search',
        builder: (context, state) => const SearchPage(),
      ),
      
      // Search results page
      GoRoute(
        path: searchResults,
        name: 'searchResults',
        builder: (context, state) {
          // Query parameters can be accessed via state.uri.queryParameters
          return const ListingsResultsPage();
        },
      ),
      
      // Property detail page
      GoRoute(
        path: '/property/:id',
        name: 'propertyDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PropertyDetailPage(propertyId: id);
        },
      ),
      
      // Add listing page
      GoRoute(
        path: addListing,
        name: 'addListing',
        builder: (context, state) => const AddListingPage(),
        routes: [
          GoRoute(
            path: 'success',
            name: 'addListingSuccess',
            builder: (context, state) => const AddListingSuccessPage(),
          ),
        ],
      ),
      
      // Dashboard routes
      GoRoute(
        path: dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
        routes: [
          // Dashboard sub-routes
          GoRoute(
            path: 'listings',
            name: 'dashboardListings',
            builder: (context, state) => const MyListingsPage(),
          ),
          GoRoute(
            path: 'favorites',
            name: 'dashboardFavorites',
            builder: (context, state) => const FavoritesPage(),
          ),
          GoRoute(
            path: 'alerts',
            name: 'dashboardAlerts',
            builder: (context, state) => const AlertsPage(),
          ),
          GoRoute(
            path: 'messages',
            name: 'dashboardMessages',
            builder: (context, state) => const MessagesPage(),
          ),
          GoRoute(
            path: 'statistics',
            name: 'dashboardStatistics',
            builder: (context, state) => const StatisticsPage(),
          ),
          GoRoute(
            path: 'settings',
            name: 'dashboardSettings',
            builder: (context, state) => const SettingsPage(),
          ),
          // Panel admina (tylko ADMIN)
          GoRoute(
            path: 'admin/users',
            name: 'dashboardAdminUsers',
            builder: (context, state) => const AdminUsersPage(),
          ),
          GoRoute(
            path: 'admin/submissions',
            name: 'dashboardAdminSubmissions',
            builder: (context, state) => const AdminSubmissionsPage(),
          ),
          GoRoute(
            path: 'admin/logs',
            name: 'dashboardAdminLogs',
            builder: (context, state) => const AdminLogsPage(),
          ),
          GoRoute(
            path: 'profile',
            name: 'dashboardProfile',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: 'documents',
            name: 'dashboardDocuments',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: 'vdr',
            name: 'dashboardVdr',
            builder: (context, state) => const FavoritesPage(),
          ),
          GoRoute(
            path: 'roi-history',
            name: 'dashboardRoiHistory',
            builder: (context, state) => const StatisticsPage(),
          ),
        ],
      ),
      
      // About page
      GoRoute(
        path: about,
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
      
      // Blog page
      GoRoute(
        path: blog,
        name: 'blog',
        builder: (context, state) => const BlogPage(),
      ),
      
      // Contact page
      GoRoute(
        path: contact,
        name: 'contact',
        builder: (context, state) => const ContactPage(),
      ),
      
      // Button Showcase (for development)
      GoRoute(
        path: buttonShowcase,
        name: 'buttonShowcase',
        builder: (context, state) => const ButtonShowcase(),
      ),
    ],
    
    // Error page
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Błąd'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Strona nie została znaleziona',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('Wróć do strony głównej'),
            ),
          ],
        ),
      ),
    ),
  );
}
