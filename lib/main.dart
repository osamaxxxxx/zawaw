import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/settings/quran_display_settings.dart';
import 'services/audio_service.dart';
import 'services/surah_download_service.dart';
import 'services/local_quran_service.dart';
import 'services/widget_sync_service.dart';
import 'services/shorts_data_seeder.dart';
import 'features/audio_player/mini_player_widget.dart';
import 'features/adhkar/adhkar_screen.dart';
import 'features/bookmarks/bookmarks_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/daily_content_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/prayer/prayer_times_screen.dart';
import 'features/quran/quran_reader_screen.dart';

// Create a global navigator key to allow dialogs and routing inside MiniPlayerWidget
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const _onboardingVersion = 2;

class NoStretchScrollBehavior extends MaterialScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding =
      prefs.getInt('onboarding_version') != _onboardingVersion;
  runApp(ZawawyApp(showOnboardingInitially: showOnboarding));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Home-screen widget sync touches prefs, the network and native widget
    // updates; none of it is needed for the first interactive frames.
    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 4),
        WidgetSyncService.refresh,
      ),
    );

    // تهيئة بيانات الشورتس
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 1500),
        () => ShortsDataSeeder().initializeIfNeeded(),
      ),
    );

    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 2),
        () => LocalQuranService().preload(),
      ),
    );

    unawaited(
      Future<void>.delayed(const Duration(seconds: 3), () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final location = UserLocation.fromPrefs(prefs) ?? UserLocation.cairo;

          await PrayerTimesScreen.scheduleOfflineNotifications(
            location: location,
          );
        } catch (e) {
          debugPrint('Error scheduling startup offline notifications: $e');
        }
      }),
    );
  });
}

class AppRootWrapper extends StatelessWidget {
  final Widget child;
  const AppRootWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Column(
              children: [
                Expanded(child: child),
                const MiniPlayerWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ZawawyApp extends StatefulWidget {
  final bool showOnboardingInitially;
  const ZawawyApp({super.key, required this.showOnboardingInitially});

  @override
  State<ZawawyApp> createState() => _ZawawyAppState();
}

class _ZawawyAppState extends State<ZawawyApp> {
  static const MethodChannel _notificationsChannel = MethodChannel(
    'zawawy_app/prayer_notifications',
  );
  static const MethodChannel _widgetsChannel = MethodChannel(
    'zawawy_app/widgets',
  );
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboardingInitially;
    _notificationsChannel.setMethodCallHandler((call) async {
      if (call.method == 'notificationNavigation' && call.arguments is String) {
        _openNotificationTarget(call.arguments as String);
      }
    });
    _widgetsChannel.setMethodCallHandler((call) async {
      if (call.method == 'notificationNavigation' && call.arguments is String) {
        _openNotificationTarget(call.arguments as String);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openInitialNotificationTarget());
    });
  }

  Future<void> _completeOnboarding() async {
    await (await SharedPreferences.getInstance()).setInt(
      'onboarding_version',
      _onboardingVersion,
    );
    if (!mounted) return;
    setState(() => _showOnboarding = false);
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _openInitialNotificationTarget() async {
    try {
      var target = await _notificationsChannel.invokeMethod<String>(
        'getLaunchTarget',
      );
      target ??= await _widgetsChannel.invokeMethod<String>('getLaunchTarget');
      if (target != null && target.isNotEmpty) {
        _openNotificationTarget(target);
      }
    } catch (e) {
      debugPrint('Error opening notification target: $e');
    }
  }

  void _openNotificationTarget(String target) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    Widget screen;
    switch (target) {
      case 'adhkar_morning':
        screen = const AdhkarScreen(initialCategoryIndex: 0);
        break;
      case 'adhkar_evening':
        screen = const AdhkarScreen(initialCategoryIndex: 1);
        break;
      case 'adhkar_sleep':
        screen = const AdhkarScreen(initialCategoryIndex: 2);
        break;
      case 'adhkar_prayer':
        screen = const AdhkarScreen(initialCategoryIndex: 3);
        break;
      case 'adhkar':
        screen = const AdhkarScreen();
        break;
      case 'quran_kahf':
        screen = const QuranReaderScreen(initialPage: 293);
        break;
      case 'daily_ayah':
        screen = const DailyContentScreen(type: DailyContentType.ayah);
        break;
      case 'daily_hadith':
        screen = const DailyContentScreen(type: DailyContentType.hadith);
        break;
      case 'saved_ayahs':
        screen = const BookmarksScreen(initialTab: 1);
        break;
      case 'bookmarks':
        screen = const BookmarksScreen();
        break;
      case 'home':
        navigator.popUntil((route) => route.isFirst);
        return;
      case 'prayer':
      default:
        screen = const PrayerTimesScreen();
        break;
    }

    navigator.push(MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(
          create: (_) => SurahDownloadService()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => QuranDisplaySettings()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'تلاوات الشيخ الزواوي',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode, // Use ThemeProvider
            scrollBehavior: const NoStretchScrollBehavior(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl, // Arabic RTL layout
                child: AppRootWrapper(child: child!),
              );
            },
            home: _showOnboarding
                ? OnboardingScreen(onComplete: _completeOnboarding)
                : const HomeScreen(),
          );
        },
      ),
    );
  }
}
