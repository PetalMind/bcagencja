import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/auth/auth_service.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/state/providers/auth_provider.dart';
import 'core/state/providers/favorites_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Avoid duplicate-app error on hot restart (web persists Firebase across restarts)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  // Web: obsługa wyniku signInWithRedirect po powrocie z Google/Apple (unikamy błędu COOP).
  // W Safari getRedirectResult() może rzucać (COOP/cookies) – nie przerywamy startu aplikacji.
  if (kIsWeb) {
    try {
      await AuthService().handleWebRedirectResult();
    } catch (_) {
      // Ignoruj błąd redirect (np. Safari, tryb prywatny) – użytkownik może zalogować się ponownie.
    }
  }

  // SharedPreferences na Safari Web może zawieść (tryb prywatny, blokada storage) – fallback do null = brak persystencji ulubionych.
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    prefs = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (_, __) {
      AppRouter.authRefreshNotifier.value++;
    });
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      
      // Router configuration
      routerConfig: AppRouter.router,
    );
  }
}
