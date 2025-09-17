// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/services.dart';
import 'package:haflaway/firebase_options.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/foundation.dart';
// import 'package:haflaway/utils/urls.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:haflaway/providers/balance_provider.dart';
import 'package:haflaway/services/balance_service.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/top_destinations/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('sw', null);
  // SystemChrome.setSystemUIOverlayStyle(
  //   const SystemUiOverlayStyle(
  //     statusBarColor: Colors.black, // or your dark color
  //     statusBarIconBrightness: Brightness.light, // For Android
  //     statusBarBrightness: Brightness.dark, // For iOS
  //   ),
  // );
  // if (kDebugMode) {
  //   try {
  //     FirebaseFirestore.instance.settings = const Settings(
  //       host: "$lokol:8080",
  //       sslEnabled: false,
  //       persistenceEnabled: false,
  //     );
  //     await FirebaseStorage.instance.useStorageEmulator(lokol, 9199);
  //   } catch (e) {
  //     debugPrint("abject: $e");
  //   }
  // }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => BalanceProvider(BalanceService(), EventPlanService()),
        ),
      ],
      child: const HfApp(),
    ),
  );
}

class HfApp extends StatelessWidget {
  const HfApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      home: const SpScr(),
      debugShowCheckedModeBanner: false,
      themeMode: provider.themeMode,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
    );
  }
}
