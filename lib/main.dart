import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:go_router/go_router.dart';
import 'package:haflaway/firebase_options.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/providers/package_provider.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/public_attendees.dart';
import 'package:haflaway/top_destinations/splash_screen.dart';
import 'package:haflaway/utils/gus_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('sw', null);

  runApp(
    Phoenix(
      child: MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => PackageProvider())],
        child: const HfApp(),
      ),
    ),
  );
}

class HfApp extends StatelessWidget {
  const HfApp({super.key});

  @override
  Widget build(BuildContext context) {
    // if (false) {
    //   return MaterialApp.router(
    //     routerConfig: router,
    //     themeMode: ThemeMode.dark,
    //     debugShowCheckedModeBanner: false,
    //     theme: GusTheme.darkTheme,
    //   );
    // } else {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720),
        child: MaterialApp(
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          theme: GusTheme.darkTheme,
        ),
      ),
    );
    // }
  }
}
