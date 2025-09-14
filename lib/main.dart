// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:haflaway/firebase_options.dart';
import 'package:haflaway/providers/balance_provider.dart';
import 'package:haflaway/services/balance_service.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/top_destinations/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('sw', null);

  // if (kDebugMode) {
  //   try {
  //     // FirebaseStorage storage = FirebaseStorage.instance;
  //     FirebaseFirestore firestore = FirebaseFirestore.instance;

  //     firestore.settings = const Settings(
  //       host: "$lokol:8080",
  //       sslEnabled: false,
  //       persistenceEnabled: false,
  //     );
  //     // await storage.useStorageEmulator("$lokol", 9199);
  //   } catch (e) {
  //     debugPrint("Abject: $e");
  //   }
  // }
  runApp(Phoenix(child: HfApp()));
}

class HfApp extends StatelessWidget {
  const HfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(colorScheme: ColorScheme.dark()),
    );
  }
}
