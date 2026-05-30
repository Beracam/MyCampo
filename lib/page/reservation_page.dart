import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../translations.dart';
import 'event_page.dart';

/// Page de réservation d'un terrain spécifique.
/// Permet de choisir une date et un créneau horaire de 2h parmi ceux disponibles.
class ReservationPage extends StatefulWidget {
  final Terrain terrain;

  const ReservationPage({super.key, required this.terrain});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  DateTime? _selectedDate;      // Jour sélectionné par l'utilisateur
  DateTime? _selectedStartTime; // Début du créneau sélectionné (Date + Heure)
  bool _isChecking = false;    // État de chargement pendant la réservation
  List<DateTime> _existingReservations = []; // Liste des réservations déjà effectuées pour ce terrain

  // Heures de fonctionnement du terrain (récupérées dynamiquement)
  late int _openHour;
  late int _openMinute;
  late int _closeHour;
  late int _closeMinute;

  @override
  void initState() {
    super.initState();
    _loadTerrainHours();          // 1. Initialise les horaires d'ouverture
    _loadExistingReservations();  // 2. Écoute les réservations existantes sur Firestore
  }

  /// Initialise les horaires d'ouverture du terrain à partir des données ou par défaut.
  void _loadTerrainHours() {
    // Valeurs par défaut
    _openHour = 8; 
    _openMinute = 15;
    _closeHour = 22;
    _closeMinute = 15;
    
    // Tente de charger les vraies heures depuis Firestore pour ce terrain
    _fetchHoursFromFirestore();
  }

  /// Récupère les horaires réels configurés par le propriétaire du terrain.
  Future<void> _fetchHoursFromFirestore() async {
    final doc = await FirebaseFirestore.instance.collection('terrains').doc(widget.terrain.id).get();
    if (doc.exists && doc.data()!['openHour'] != null) {
      if (mounted) {
        setState(() {
          _openHour = doc.data()!['openHour'];
          _openMinute = doc.data()!['openMinute'];
          _closeHour = doc.data()!['closeHour'];
          _closeMinute = doc.data()!['closeMinute'];
        });
      }
    }
  }

  /// Écoute en temps réel les réservations de ce terrain pour bloquer les créneaux déjà pris.
  void _loadExistingReservations() {
    FirebaseFirestore.instance
        .collection('reservations')
        .where('terrainId', isEqualTo: widget.terrain.id)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _existingReservations = snapshot.docs.map((doc) {
            Timestamp ts = doc.get('date');
            int hour = doc.get('hour');
            int minute = doc.get('minute');
            DateTime d = ts.toDate();
            // Reconstruit un objet DateTime pour la comparaison
            return DateTime(d.year, d.month, d.day, hour, minute);
          }).toList();
        });
      }
    });
  }

  /// Génère la liste des créneaux de 2h possibles entre l'ouverture et la fermeture.
  List<TimeOfDay> _generateSlots() {
    List<TimeOfDay> slots = [];
    DateTime current = DateTime(2000, 1, 1, _openHour, _openMinute);
    final DateTime end = DateTime(2000, 1, 1, _closeHour, _closeMinute);

    // On boucle tant qu'on peut ajouter un bloc de 2h
    while (current.add(const Duration(hours: 2)).isBefore(end) || 
           current.add(const Duration(hours: 2)).isAtSameMomentAs(end)) {
      slots.add(TimeOfDay(hour: current.hour, minute: current.minute));
      current = current.add(const Duration(hours: 2));
    }
    return slots;
  }

  /// Vérifie si un créneau spécifique est déjà réservé dans la base de données.
  bool _isSlotOccupied(DateTime start) {
    for (var existing in _existingReservations) {
      if (existing.year == start.year &&
          existing.month == start.month &&
          existing.day == start.day &&
          existing.hour == start.hour &&
          existing.minute == start.minute) {
        return true;
      }
    }
    return false;
  }

  /// Enregistre la réservation dans Firestore.
  Future<void> _confirmReservation(String lang) async {
    if (_selectedDate == null || _selectedStartTime == null) return;
    setState(() => _isChecking = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      // Génère un ID unique basé sur le temps pour éviter les doublons
      final String docId = "${widget.terrain.id}_${_selectedStartTime!.millisecondsSinceEpoch}";

      await FirebaseFirestore.instance.collection('reservations').doc(docId).set({
        'terrainId': widget.terrain.id,
        'terrainTitle': widget.terrain.title,
        'terrainImage': widget.terrain.imagePath,
        'userId': user?.uid,
        'date': _selectedDate,
        'hour': _selectedStartTime!.hour,
        'minute': _selectedStartTime!.minute,
        'durationMinutes': 120, // Bloc fixe de 2h
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Translations.translate('success_reservation', lang)), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Retour à la liste
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<TimeOfDay> availableSlots = _generateSlots();

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, _) {
        final String lang = currentLocale.languageCode;

        return Scaffold(
          appBar: AppBar(title: Text(Translations.translate('reservation_title', lang))),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte résumé du terrain sélectionné
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(widget.terrain.imagePath, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.terrain.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(widget.terrain.price, style: const TextStyle(color: Colors.green, fontSize: 12)),
                            Text("${_openHour}:${_openMinute.toString().padLeft(2, '0')} - ${_closeHour}:${_closeMinute.toString().padLeft(2, '0')}", 
                                style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Étape 1 : Choisir la date
                Text("1. ${Translations.translate('select_date', lang)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.green),
                  title: Text(_selectedDate == null 
                      ? Translations.translate('select_date', lang) 
                      : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() { _selectedDate = picked; _selectedStartTime = null; });
                  },
                  shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 25),

                // Étape 2 : Choisir le créneau dans la grille
                if (_selectedDate != null) ...[
                  Text("2. ${Translations.translate('select_time', lang)} (2h / slot)", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: availableSlots.length,
                      itemBuilder: (context, index) {
                        final time = availableSlots[index];
                        final DateTime slotStart = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, time.hour, time.minute);
                        final DateTime slotEnd = slotStart.add(const Duration(hours: 2));
                        final bool occupied = _isSlotOccupied(slotStart);
                        final bool isSelected = _selectedStartTime == slotStart;

                        return InkWell(
                          onTap: occupied ? null : () => setState(() => _selectedStartTime = slotStart),
                          child: Container(
                            decoration: BoxDecoration(
                              color: occupied 
                                  ? Colors.red.withOpacity(0.2) 
                                  : (isSelected ? Colors.green : Colors.green.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? Colors.green : (occupied ? Colors.red : Colors.green.withOpacity(0.3))),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "${time.hour}:${time.minute.toString().padLeft(2, '0')} - ${slotEnd.hour}:${slotEnd.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontSize: 12,
                                color: occupied ? Colors.red[800] : (isSelected ? Colors.white : Colors.green[800]),
                                decoration: occupied ? TextDecoration.lineThrough : null, // Barre le texte si occupé
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else const Spacer(),

                // Bouton de confirmation finale
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (_selectedStartTime != null && !_isChecking) 
                      ? () => _confirmReservation(lang)
                      : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isChecking 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(Translations.translate('confirm_reservation', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
