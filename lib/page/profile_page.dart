import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mycampo/page/add_terrain_page.dart';
import '../main.dart';
import '../translations.dart';
import '../firebase_auth/auth.dart';
import 'event_page.dart';

/// Page de profil de l'utilisateur.
/// Permet de consulter ses informations personnelles, ses publications de terrains
/// et l'historique de ses réservations.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// Affiche une boîte de dialogue pour confirmer l'annulation d'une réservation.
  Future<void> _cancelReservation(BuildContext context, String reservationId, String lang) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate('cancel_confirm_title', lang)),
        content: Text(Translations.translate('cancel_confirm_msg', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Translations.translate('cancel_btn', lang), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(Translations.translate('delete', lang), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Supprime le document de réservation dans la collection 'reservations'
        await FirebaseFirestore.instance.collection('reservations').doc(reservationId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translations.translate('cancel_success', lang)), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Affiche une boîte de dialogue pour modifier le numéro de téléphone.
  Future<void> _editPhoneNumber(BuildContext context, String currentPhone, String userId, String lang) async {
    final controller = TextEditingController(text: currentPhone);
    bool? save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate('edit_phone_title', lang)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: Translations.translate('phone_label', lang),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Translations.translate('cancel_btn', lang), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final phone = controller.text.trim();
              final regex = RegExp(r'^\+\d{1,3}([ .-]?\(?\d+\)?){1,5}$');
              if (!regex.hasMatch(phone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                      Translations.translate('invalid_phone', lang)
                  )),
                );
                return; // Empêche la fermeture du dialogue
              }
              Navigator.pop(context, true); // Numéro valide
            },
            child: Text(
              Translations.translate('save', lang), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (save == true) {
      try {
        // Met à jour le champ 'phone' de l'utilisateur dans Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'phone': controller.text.trim(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translations.translate('phone_updated', lang)), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Affiche la liste des réservations faites sur un terrain publié par l'utilisateur.
  void _showFieldReservations(BuildContext context, String terrainId, String terrainTitle, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${Translations.translate('field_reservations_title', lang)}: $terrainTitle",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reservations')
                      .where('terrainId', isEqualTo: terrainId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)  return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text(Translations.translate('no_reservations_field', lang)));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final resData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        String dateStr = "Date inconnue";
                        if (resData['date'] != null) {
                          final DateTime d = (resData['date'] as Timestamp).toDate();
                          dateStr = "${d.day}/${d.month}/${d.year}";
                        }
                        final int hour = resData['hour'] ?? 0;
                        final int minute = resData['minute'] ?? 0;
                        final String timeStr = "$hour:${minute.toString().padLeft(2, '0')}";
                        final String userId = resData['userId'] ?? "";

                        // Recherche les informations de l'utilisateur qui a effectué la réservation
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                          builder: (context, userSnapshot) {
                            String reserverPseudo = "...";
                            String reserverEmail = "";

                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                              reserverPseudo = userData['pseudo'] ?? "Inconnu";
                              reserverEmail = userData['email'] ?? "";
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.person)),
                                title: Text(reserverPseudo, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("$reserverEmail\n$dateStr à $timeStr"),
                                trailing: const Icon(Icons.check_circle, color: Colors.green),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser; // Récupère l'utilisateur connecté

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, _) {
        final String lang = currentLocale.languageCode;

        return Scaffold(
          appBar: AppBar(
            title: Text(Translations.translate('profile_title', lang)),
            actions: [
              IconButton(
                onPressed: () => Auth().logout(), // Bouton de déconnexion
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Column(
            children: [
              // Section Informations de l'utilisateur
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  String pseudo = "User";
                  String phone = "";
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    pseudo = data['pseudo'] ?? "User";
                    phone = data['phone'] ?? "";
                  }
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.green,
                          child: Text(pseudo[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white)),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pseudo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Text(phone.isNotEmpty ? phone : "---"),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                    onPressed: () => _editPhoneNumber(context, phone, user?.uid ?? "", lang),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              
              // Onglets pour gérer les deux listes
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.green,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.green,
                        tabs: [
                          Tab(text: Translations.translate('my_publications', lang)),
                          Tab(text: Translations.translate('my_reservations', lang)),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildMyPublications(context, user?.uid, lang),
                            _buildMyReservations(context, user?.uid, lang),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget affichant les terrains publiés par l'utilisateur connecté.
  Widget _buildMyPublications(BuildContext context, String? uid, String lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('terrains')
          .where('publisherId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(Translations.translate('no_publications', lang)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final terrainData = doc.data() as Map<String, dynamic>;
            final terrain = Terrain.fromFirestore(doc);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(terrain.imagePath, width: 50, height: 50, fit: BoxFit.cover),
                ),
                title: Text(terrain.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(terrain.price, style: const TextStyle(color: Colors.green)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icone calendrier pour voir le suivi des réservations
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: Colors.blue),
                      onPressed: () => _showFieldReservations(context, doc.id, terrain.title, lang),
                    ),
                    // Icone édition pour modifier les infos du terrain
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTerrainPage(
                              initialData: terrainData,
                              terrainId: doc.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Widget affichant les réservations faites par l'utilisateur connecté sur d'autres terrains.
  Widget _buildMyReservations(BuildContext context, String? uid, String lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_note, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(Translations.translate('no_reservations', lang)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            DateTime date = DateTime.now();
            if (data['date'] != null) date = (data['date'] as Timestamp).toDate();
            
            final String timeStr = "${data['hour']}:${data['minute'].toString().padLeft(2, '0')}";

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.event_available, color: Colors.green),
                title: Text(data['terrainTitle'] ?? 'Terrain'),
                subtitle: Text("${date.day}/${date.month}/${date.year} à $timeStr"),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  onPressed: () => _cancelReservation(context, doc.id, lang),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
