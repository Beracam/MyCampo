import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mycampo/page/redirection_page.dart';

import 'firebase_options.dart';

/// Point d'entrée principal de l'application.
Future<void> main() async {
  // S'assure que les services Flutter sont initialisés avant toute autre opération
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Firebase avec les options générées pour la plateforme actuelle
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );
  
  // Lancement de l'application
  runApp(const MyApp());
}

/// Notificateur global pour la gestion du thème (Clair/Sombre)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

/// Notificateur global pour la gestion de la langue (Français par défaut)
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('fr'));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Écouteur de changement de thème
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        // Écouteur de changement de langue
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, currentLocale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'MyCampo',
              locale: currentLocale, // Applique la langue actuelle
              
              // Configuration du thème Clair
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                colorSchemeSeed: Colors.green,
              ),
              
              // Configuration du thème Sombre
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorSchemeSeed: Colors.green,
              ),
              
              themeMode: currentMode, // Gère le passage Clair/Sombre
              home: const RedirectionPage(), // Redirection vers la page appropriée selon l'auth
            );
          },
        );
      },
    );
  }
}
