import 'package:flutter/material.dart';
import 'package:mycampo/page/login_page.dart';
import '../main.dart';
import '../translations.dart';

/// Page d'accueil (Landing Page) de l'application.
/// Présente l'application et incite l'utilisateur à se connecter ou s'inscrire.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Écoute les changements de langue pour mettre à jour les textes instantanément
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, _) {
        final String lang = currentLocale.languageCode;
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        // Couleur dominante extraite de l'illustration pour une fusion naturelle
        const Color imageMatchColor = Color(0xFFD4E1A1);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent, // AppBar invisible pour le design
            elevation: 0,
            actions: [
              // Menu de sélection de la langue
              PopupMenuButton<String>(
                icon: Icon(Icons.language, color: isDark ? Colors.white : Colors.black87),
                onSelected: (String language) {
                  if (language == 'Anglais') localeNotifier.value = const Locale('en');
                  else if (language == 'Espagnol') localeNotifier.value = const Locale('es');
                  else if (language == 'Italien') localeNotifier.value = const Locale('it');
                  else localeNotifier.value = const Locale('fr');
                },
                itemBuilder: (context) => ['Anglais', 'Espagnol', 'Français', 'Italien']
                    .map((l) => PopupMenuItem(value: l, child: Text(l)))
                    .toList(),
              ),
              // Bouton pour basculer entre mode clair et sombre
              IconButton(
                onPressed: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          extendBodyBehindAppBar: true, // Permet au contenu de passer sous l'AppBar transparente
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // Dégradé de fond s'adaptant au thème actuel
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                  ? [Colors.black, Colors.grey[900]!] 
                  : [imageMatchColor, Colors.white],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      // Illustration principale avec bordures arrondies
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: SizedBox(
                          height: 250,
                          child: Image.asset(
                            "assets/images/campo.jpg",
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.sports_soccer, size: 100, color: Colors.green),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Nom de l'application
                      const Text(
                        "MY Campo",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: Color(0xFF2E4D2E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Slogan traduit
                      Text(
                        Translations.translate('home_slogan', lang),
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Texte d'introduction traduit
                      Text(
                        Translations.translate('home_intro', lang),
                        style: TextStyle(
                          fontSize: 20,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 80),
                      
                      // Pied de page (Footer)
                      const Divider(),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          const Text(
                            "© 2024 MY Campo - All rights reserved",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.email, size: 14, color: Colors.grey),
                              const SizedBox(width: 5),
                              const Text(
                                "mycodeprogramone@gmail.com",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 100), // Espace pour ne pas cacher le contenu sous le bouton flottant
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bouton flottant pour commencer l'aventure
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            height: 60,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              backgroundColor: const Color(0xFF4A633F),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              label: Text(
                Translations.translate('get_started', lang),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}
