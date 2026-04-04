import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../firebase_options.dart';
import 'admin_app.dart';

Future<void> bootstrapAdminApp({bool usePathUrlStrategy = false}) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (usePathUrlStrategy && kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  runApp(const ProviderScope(child: AdminApp()));
}
