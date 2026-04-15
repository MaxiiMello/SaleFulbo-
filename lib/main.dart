import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // App still runs in demo mode; Firebase config may have issues.
    // Check firebase_options.dart and Google Cloud Console.
  }
  await LocalStorageService.instance.init();
  runApp(const ProviderScope(child: SaleFulboApp()));
}
