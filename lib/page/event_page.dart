import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mycampo/page/add_terrain_page.dart';
import 'package:mycampo/page/reservation_page.dart';
import 'package:mycampo/page/profile_page.dart';
import '../main.dart';
import '../firebase_auth/auth.dart';
import '../translations.dart';

/// Modèle de données pour un Terrain.
class Terrain { // Classe de données
  final String id;
  final String imagePath;
  final String title;
  final String price;
  final String location;
  final int playersCount;
  final double rating;

  Terrain({ // Constructeur
    required this.id,
    required this.imagePath,
    required this.title,
    required this.price,
    required this.location,
    required this.playersCount,
    required this.rating,
  });

  /// Convertit un document Firestore en objet Terrain.
  factory Terrain.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Terrain(
      id: doc.id,
      title: data['title'] ?? 'Sans titre',
      price: data['price'] ?? '0£',
      location: data['location'] ?? 'Inconnue',
      playersCount: data['playersCount'] ?? 5,
      imagePath: data['imagePath'] ?? 'assets/images/campo3.jpg',
      rating: (data['rating'] ?? 5.0).toDouble(),
    );
  }
}

/// Page principale, Affiche la liste des terrains disponibles.
class EventPage extends StatefulWidget {
  const EventPage({super.key, required this.title});

  final String title;

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  int _selectedIndex = 0; // Index pour la navigation par onglets (Explorer / Profil)
  final User? user = Auth().currentUser; // Récupère l'utilisateur connecté
  final TextEditingController _searchController = TextEditingController(); // Contrôleur pour la barre de recherche
  String _searchQuery = ""; // Chaîne de recherche

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose(); // Libère les ressources
  }

  /// Change de page lors du clic sur la barre de navigation.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Écoute les changements de langue
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, _) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final String lang = currentLocale.languageCode;

        // Liste des écrans disponibles via la BottomNavigationBar
        final List<Widget> _pages = [
          _buildExplorePage(isDark, lang), // Page "Explorer"
          const ProfilePage(), // Page "Profil"
        ];

        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.green,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.explore),
                label: Translations.translate('nav_explore', lang),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: Translations.translate('nav_profile', lang),
              ),
            ],
          ),
          // Bouton flottant pour ajouter un terrain (visible seulement sur l'onglet Explorer)
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: _selectedIndex == 0 ? Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddTerrainPage()),
                );
              },
              label: Text(Translations.translate('add_terrain', lang)),
              icon: const Icon(Icons.add),
              backgroundColor: Colors.white.withOpacity(0.85),
              foregroundColor: const Color(0xFF4A633F),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
              ),
            ),
          ) : null,
        );
      },
    );
  }

  /// Construit la vue "Explorer" (Liste des terrains + Recherche).
  Widget _buildExplorePage(bool isDark, String lang) {
    return Column(
      children: [
        AppBar(
          title: Text(Translations.translate('app_title', lang)),
          actions: [
            // Sélecteur de langue
            PopupMenuButton<String>(
              icon: const Icon(Icons.language),
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
            // Toggle Thème
            IconButton(
              onPressed: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            ),
            // Déconnexion
            IconButton(
              onPressed: () => Auth().logout(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        // Bienvenue avec le pseudo de l'utilisateur
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
          builder: (context, snapshot) {
            String pseudo = "Utilisateur";
            if (snapshot.hasData && snapshot.data!.exists) {
              pseudo = snapshot.data!.get('pseudo') ?? "Utilisateur";
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: isDark ? Colors.grey[900] : Colors.green[50],
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(pseudo[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Translations.translate('welcome', lang), style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(pseudo, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: Translations.translate('search_hint', lang),
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        
        // Liste des terrains récupérée depuis Firestore en temps réel
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('terrains')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text(Translations.translate('no_terrain', lang)));
              }

              final List<Terrain> allTerrains = snapshot.data!.docs
                  .map((doc) => Terrain.fromFirestore(doc))
                  .toList();

              // Filtrage local selon la saisie dans la barre de recherche
              final filteredTerrains = allTerrains.where((terrain) {
                final searchLower = _searchQuery.toLowerCase();
                return terrain.title.toLowerCase().contains(searchLower) ||
                    terrain.location.toLowerCase().contains(searchLower);
              }).toList();

              if (filteredTerrains.isEmpty) {
                return Center(child: Text(Translations.translate('no_terrain', lang)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredTerrains.length,
                itemBuilder: (context, index) => _buildTerrainCard(filteredTerrains[index], lang),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Construction de la carte terrain
  Widget _buildTerrainCard(Terrain terrain, String lang) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du terrain
          ClipRRect( // Arrondi les coins
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.asset(
              terrain.imagePath,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  terrain.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A3344),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "${terrain.price} /h",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 8),
                // Localisation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        terrain.location,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Footer de la carte : Icônes joueurs et Bouton Réserver
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : const Color(0xFFF0F2F4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: -2,
                            children: List.generate(terrain.playersCount, (index) { // Génère des Icônes joueurs
                              bool isGoalkeeper = index == terrain.playersCount - 1; // Dernier joueur est le gardien
                              return Icon(
                                Icons.person, // Icône joueur
                                size: 14,
                                color: isGoalkeeper ? const Color(0xFF8A99A4) : const Color(0xFFC84040), // Couleur du gardien
                              );
                            }),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${terrain.playersCount} vs ${terrain.playersCount}", // Affiche le nombre de joueurs
                            style: const TextStyle(fontSize: 11, color: Color(0xFF5E7381), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ReservationPage(terrain: terrain)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        Translations.translate('reserve', lang),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
