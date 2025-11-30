import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

import 'services/firebase_service.dart';
import 'screens/swipe_screen.dart';
import 'screens/list_item_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/my_listings_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FirebaseService(),
      child: MaterialApp(
        title: 'Bartr',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0E0A),
          fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF00FF41),
            secondary: const Color(0xFF39FF14),
            surface: const Color(0xFF1A251A),
            background: const Color(0xFF0A0E0A),
            error: const Color(0xFFFF4444),
          ),
          textTheme: GoogleFonts.jetBrainsMonoTextTheme(ThemeData.dark().textTheme).copyWith(
            bodyLarge: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            bodyMedium: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            bodySmall: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            displayLarge: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            displayMedium: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            displaySmall: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            headlineLarge: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            headlineMedium: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            headlineSmall: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            titleLarge: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            titleMedium: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            titleSmall: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            labelLarge: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            labelMedium: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            labelSmall: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF1A251A),
            elevation: 8,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF0A0E0A),
            elevation: 0,
            titleTextStyle: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41), fontSize: 20),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const EntryRouter(),
          '/swipe': (context) => const SwipeScreen(),
          '/list': (context) => const ListItemScreen(),
          '/matches': (context) => const MatchesScreen(),
        },
      ),
    );
  }
}

class EntryRouter extends StatelessWidget {
  const EntryRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context, listen: false);

    return FutureBuilder<bool>(
      future: service.ensureSignedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to Firebase...'),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Firebase Configuration Error',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Please enable these in Firebase Console:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Authentication > Anonymous'),
                    const Text('2. Firestore Database'),
                    const Text('3. Storage'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Retry
                        (context as Element).markNeedsBuild();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const MainNavigation();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SwipeScreen(),
    const MatchesScreen(),
    const MyListingsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[700],
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_carousel),
            label: 'Swipe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'My Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
