import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Bartr — Sign in')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await service.ensureSignedIn();
            Navigator.of(context).pushReplacementNamed('/swipe');
          },
          child: const Text('Continue (Anonymous)'),
        ),
      ),
    );
  }
}
