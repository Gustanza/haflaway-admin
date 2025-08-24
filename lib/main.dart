// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
// import 'package:flutter/services.dart';
import 'package:haflaway/firebase_options.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/top_destinations/event_dash/attendess/attendees.dart';
import 'package:haflaway/top_destinations/landing/landing.dart';
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

  runApp(
    MaterialApp.router(
      routerConfig: router,
      themeMode: ThemeMode.dark,
      theme: ThemeData(colorScheme: ColorScheme.dark()),
      debugShowCheckedModeBanner: false,
    ),
  );
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const LandingPage();
      },
    ),
    GoRoute(
      path: '/hfnte/:eId/invites',
      builder: (context, state) {
        return HfApp(eId: state.pathParameters['eId'] ?? "");
      },
    ),
  ],
);

class HfApp extends StatelessWidget {
  final String eId;
  const HfApp({super.key, required this.eId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection(ecol).doc(eId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var source = (snapshot.data as dynamic);
          if (source == null && source.data() == null) {
            return buildEmptyState();
          }
          Event edata = Event.fromMap(source.id, source.data());
          return Attendees(
            edata: edata,
            kardType: KardType.invitation,
            title: "Invitations",
          );
        } else if (snapshot.hasError) {
          return buildErrorState();
        } else {
          return Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }
}
