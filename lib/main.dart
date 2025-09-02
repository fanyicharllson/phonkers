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
import 'package:phonkers/view/widget/network_widget/network_status_listener.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Network Service first (it's a singleton)
  final networkService = NetworkStatusService();
  await networkService.initialize();

  // Initialize other services
  await SpotifyApiService.initialize();
  YouTubeApiService.initialize();
  await AudioPlayerService.initialize();

  // Test API connections (with network check)
  if (networkService.isOnline) {
    final isSpotifyWorking = await SpotifyApiService.testConnection();
    final isYouTubeWorking = await YouTubeApiService.testConnection();
    print('Spotify API working: $isSpotifyWorking');
    print('YouTube API working: $isYouTubeWorking');
  } else {
    print('No internet connection - skipping API tests');
  }

  print('Audio app service initialized!');

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't dispose the network service here as it's a singleton
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App is back in foreground - refresh network status
        print('App resumed');
        _networkService.refreshStatus();
        break;
      case AppLifecycleState.paused:
        print('App paused');
        break;
      case AppLifecycleState.detached:
        // App is being killed - clean up
        _networkService.dispose();
        break;
      case AppLifecycleState.inactive:
        break;
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
