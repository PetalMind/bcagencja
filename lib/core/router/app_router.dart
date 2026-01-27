import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_page.dart';
import '../../features/search/search_page.dart';
import '../../features/listings/listings_results_page.dart';
import '../../features/property/property_detail_page.dart';
import '../../features/add_listing/add_listing_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/dashboard/pages/my_listings_page.dart';
import '../../features/dashboard/pages/favorites_page.dart';
import '../../features/dashboard/pages/alerts_page.dart';
import '../../features/dashboard/pages/messages_page.dart';
import '../../features/dashboard/pages/statistics_page.dart';
import '../../features/dashboard/pages/settings_page.dart';
import '../../features/about/about_page.dart';
import '../../features/blog/blog_page.dart';
import '../../features/contact/contact_page.dart';

/// Application router configuration
class AppRouter {
  // Route names
  static const String home = '/';
  static const String search = '/search';
  static const String searchResults = '/search/results';
  static const String propertyDetail = '/property/:id';
  static const String addListing = '/add-listing';
  static const String dashboard = '/dashboard';
  static const String dashboardListings = '/dashboard/listings';
  static const String dashboardFavorites = '/dashboard/favorites';
  static const String dashboardAlerts = '/dashboard/alerts';
  static const String dashboardMessages = '/dashboard/messages';
  static const String dashboardStatistics = '/dashboard/statistics';
  static const String dashboardSettings = '/dashboard/settings';
  static const String about = '/about';
  static const String blog = '/blog';
  static const String contact = '/contact';
  
  /// Router configuration
  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,
    routes: [
      // Home page
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
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
