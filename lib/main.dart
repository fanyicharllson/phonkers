import 'package:flutter/material.dart';
import 'package:phonkers/data/service/audio_player_service.dart';
import 'package:phonkers/data/service/spotify_api_service.dart';
import 'package:phonkers/data/service/youtube_api_service.dart';
import 'package:phonkers/firebase_auth_service/auth_state_manager.dart';
import 'package:phonkers/view/pages/auth_page.dart';
import 'package:phonkers/view/pages/main_page.dart';
import 'package:phonkers/view/pages/welcome_info_page.dart';
import 'package:phonkers/view/pages/welcome_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:phonkers/view/widget/network_status_listener.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SpotifyApiService.initialize();

  YouTubeApiService.initialize();

  // Test Spotify connection
  final isWorking = await SpotifyApiService.testConnection();
  print('Spotify API working: $isWorking');

  final youtubeWorking = await YouTubeApiService.testConnection();
  print('YouTube API working: $youtubeWorking');

  // Initialize Audio Player
  await AudioPlayerService.initialize();
  print('Audio app service initialized!');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // This widget is the root of your application.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        // App is back in foreground - refresh if needed
        print('App resumed');
        break;
      case AppLifecycleState.paused:
        // App is in background
        print('App paused');
        break;
      case AppLifecycleState.detached:
        // App is being killed
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NetworkStatusListener(
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
