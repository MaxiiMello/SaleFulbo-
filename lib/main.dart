import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // App still runs; login with Google will require Firebase setup to succeed.
  }
  await LocalStorageService.instance.init();
  runApp(const ProviderScope(child: SaleFulboApp()));
}
