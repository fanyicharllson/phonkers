import 'package:flutter/material.dart';
import 'package:phonkers/data/service/audio_player_service.dart';
import 'package:phonkers/data/service/spotify_api_service.dart';
import 'package:phonkers/data/service/youtube_api_service.dart';
import 'package:phonkers/data/service/network_status_service.dart';
import 'package:phonkers/firebase_auth_service/auth_state_manager.dart';
import 'package:phonkers/view/pages/auth_page.dart';
import 'package:phonkers/view/pages/main_page.dart';
import 'package:phonkers/view/pages/welcome_info_page.dart';
import 'package:phonkers/view/pages/welcome_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:phonkers/view/screens/search_screen.dart';

import 'package:phonkers/view/widget/network_widget/network_status_listener.dart';
import 'firebase_options.dart';

// 🔔 Background handler (when push comes and app is terminated/in background)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Network Service first (singleton)
  final networkService = NetworkStatusService();
  await networkService.initialize();

  // Initialize other services
  await SpotifyApiService.initialize();
  YouTubeApiService.initialize();
  await AudioPlayerService.initialize();

  // Test API connections if online
  if (networkService.isOnline) {
    final isSpotifyWorking = await SpotifyApiService.testConnection();
    final isYouTubeWorking = await YouTubeApiService.testConnection();
    debugPrint('Spotify API working: $isSpotifyWorking');
    debugPrint('YouTube API working: $isYouTubeWorking');
  } else {
    debugPrint('No internet connection - skipping API tests');
  }

  debugPrint('Audio app service initialized!');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final NetworkStatusService _networkService = NetworkStatusService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _setupNotifications();
    _checkInitialMessage();
    _listenForNotificationClicks();
  }

  /// 🔔 Setup FCM
  void _setupNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // iOS permission
    await messaging.requestPermission();

    // Subscribe all users to trending phonks
    await messaging.subscribeToTopic("trending-phonks");
  }

  /// 🔔 Cold start (app opened by tapping notification when closed)
  void _checkInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null && initialMessage.data['phonkTitle'] != null) {
      final phonkTitle = initialMessage.data['phonkTitle'];
      _goToSearch(phonkTitle);
    }
  }

  /// 🔔 Handle notification taps and foreground messages
  void _listenForNotificationClicks() {
    // Background → tap notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final phonkTitle = message.data['phonkTitle'];
      if (phonkTitle != null) {
        _goToSearch(phonkTitle);
      }
    });

    // Foreground → app is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint("Foreground push: ${message.notification!.title}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification!.title ?? "New Trending Phonk"),
            backgroundColor: Colors.purple,
          ),
        );
      }
    });
  }

  /// Navigate to SearchScreen with initial query
  void _goToSearch(String phonkName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: phonkName)),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        _networkService.refreshStatus();
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused');
        break;
      case AppLifecycleState.detached:
        _networkService.dispose();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NetworkStatusListener(
      showInitialStatus: false,
      child: MaterialApp(
        title: 'Phonkers',
        debugShowCheckedModeBanner: false,
        routes: {
          '/main': (context) => MainPage(),
          '/welcome': (context) => const WelcomePage(),
          '/welcome-info': (context) => const WelcomeInfoPage(),
          '/auth': (context) => const AuthPage(),
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
        ),
        home: const AuthStateManager(),
      ),
    );
  }
}
