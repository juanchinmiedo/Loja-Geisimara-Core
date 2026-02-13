import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/provider/locale_provider.dart';
import 'package:salon_app/provider/admin_mode_provider.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/provider/booking_view_provider.dart';

import 'package:salon_app/screens/introduction/spalsh_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (_) {
            final provider = UserProvider();
            provider.bindAuthStream(); // ✅
            return provider;
          },
        ),
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider(),
        ),
        ChangeNotifierProvider<AdminModeProvider>(
          create: (_) => AdminModeProvider(),
        ),
        ChangeNotifierProvider<AdminNavProvider>(
          create: (_) => AdminNavProvider(),
        ),
        ChangeNotifierProvider<BookingViewProvider>(
          create: (_) => BookingViewProvider(),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Geisimara Salon Booking',
            theme: ThemeData(primarySwatch: Colors.blue),
            home: const SplashScreen(),
            locale: localeProvider.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              S.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
          );
        },
      ),
    );
  }
}
