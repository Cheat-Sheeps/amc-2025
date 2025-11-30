import 'dart:async';

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
import 'screens/chat_screen.dart';
import 'models/chat_message.dart';
import 'package:geolocator/geolocator.dart';


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
          fontFamily: GoogleFonts.roboto().fontFamily,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF00FF41),
            secondary: const Color(0xFF39FF14),
            surface: const Color(0xFF1A251A),
            background: const Color(0xFF0A0E0A),
            error: const Color(0xFFFF4444),
          ),
          textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
            // Body text uses Roboto for readability
            bodyLarge: GoogleFonts.roboto(color: const Color(0xFF00FF41)),
            bodyMedium: GoogleFonts.roboto(color: const Color(0xFF00FF41)),
            bodySmall: GoogleFonts.roboto(color: const Color(0xFF00FF41)),
            // Display styles use JetBrains Mono
            displayLarge: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            displayMedium: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            displaySmall: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            // Headlines use JetBrains Mono
            headlineLarge: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            headlineMedium: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            headlineSmall: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            // Titles use JetBrains Mono
            titleLarge: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            titleMedium: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            titleSmall: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41)),
            // Labels use Roboto for readability
            labelLarge: GoogleFonts.roboto(color: const Color(0xFF00FF41)),
            labelMedium: GoogleFonts.roboto(color: const Color(0xFF00FF41)),
            labelSmall: GoogleFonts.roboto(color: const Color(0xFF00FF41)),
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

  // Notification State
  StreamSubscription? _matchesSubscription;
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  final Set<String> _processedMessageIds = {};
  final DateTime _startTime = DateTime.now();

  final List<Widget> _screens = [
    const SwipeScreen(),
    const MatchesScreen(),
    const MyListingsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Setup listeners after frame to ensure Provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationListeners();
      _updateUserLocation();
    });
  }

  @override
  void dispose() {
    _matchesSubscription?.cancel();
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _updateUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator. isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied.');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Update in Firebase
      if (mounted) {
        final service = Provider.of<FirebaseService>(context, listen: false);
        await service. updateUserLocation(position);
        debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      // Silently fail - location is optional
      debugPrint('Could not update location: $e');
    }
  }

  void _setupNotificationListeners() {
    final service = Provider.of<FirebaseService>(context, listen: false);

    _matchesSubscription = service.streamMatches().listen((matches) {
      for (final match in matches) {
        final matchId = match['id'] as String;
        // If we haven't subscribed to this match's messages yet
        if (!_messageSubscriptions.containsKey(matchId)) {
          _messageSubscriptions[matchId] = service.streamMessages(matchId).listen((messages) {
            if (messages.isNotEmpty) {
              final lastMsg = messages.last;

              // Logic:
              // 1. Message must be received AFTER this app session started (don't notify for old history)
              // 2. Message sender must NOT be the current user
              // 3. Message must not have been processed/notified already in this session
              if (lastMsg.timestamp.isAfter(_startTime) &&
                  lastMsg.senderId != service.user?.uid &&
                  !_processedMessageIds.contains(lastMsg.id)) {

                _processedMessageIds.add(lastMsg.id);
                _showNotification(match, lastMsg);
              }
            }
          });
        }
      }
    });
  }

  Future<void> _showNotification(Map<String, dynamic> match, ChatMessage message) async {
    if (!mounted) return;

    final service = Provider.of<FirebaseService>(context, listen: false);
    final users = (match['users'] as List<dynamic>?) ?? [];
    final otherUserId = users.firstWhere((id) => id != service.user?.uid, orElse: () => 'unknown');

    final profile = await service.getUserProfile(otherUserId);
    final displayName = profile?.displayName ?? 'Survivor';

    if (!mounted) return;

    // notif
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 4,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat_bubble, color: Theme.of(context).colorScheme.primary),
        ),
        content: Text(
          '> $displayName: ${message.text}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text('DISMISS', style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    matchId: match['id'],
                    otherUserId: otherUserId,
                    otherUserName: displayName,
                    trustScore: profile?.trustScore ?? 5.0,
                    itemId: match['itemId'],
                    matchedItemId: match['matchedItemId'],
                  ),
                ),
              );
            },
            child: Text('REPLY', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ),
        ],
      ),
    );

    // auto hide stuff
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

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
            icon: Icon(Icons.sell),
            label: 'My Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}