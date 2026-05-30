import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../translations.dart';

/// Page permettant d'ajouter ou de modifier un terrain.
/// Si [initialData] et [terrainId] sont fournis, la page passe en mode "édition".
class AddTerrainPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? terrainId;

  const AddTerrainPage({super.key, this.initialData, this.terrainId});

  @override
  State<AddTerrainPage> createState() => _AddTerrainPageState();
}

class _AddTerrainPageState extends State<AddTerrainPage> {
  // Clé pour la validation du formulaire
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs de saisie
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _playersController;
  
  // Heures d'ouverture et de fermeture par défaut
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 15);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 15);
  
  // État de chargement pendant la publication
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // Initialisation des contrôleurs avec les données existantes si on est en mode édition
    _nameController = TextEditingController(text: widget.initialData?['title']);
    _priceController = TextEditingController(
        text: widget.initialData?['price']?.toString().replaceAll('£', ''));
    _locationController = TextEditingController(text: widget.initialData?['location']);
    _playersController = TextEditingController(
        text: widget.initialData?['playersCount']?.toString());
    
    // Récupération des horaires si existants
    if (widget.initialData?['openHour'] != null) {
      _openTime = TimeOfDay(hour: widget.initialData!['openHour'], minute: widget.initialData!['openMinute']);
    }
    if (widget.initialData?['closeHour'] != null) {
      _closeTime = TimeOfDay(hour: widget.initialData!['closeHour'], minute: widget.initialData!['closeMinute']);
    }
  }

  @override
  void dispose() {
    // Nettoyage des contrôleurs
    _nameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _playersController.dispose();
    super.dispose();
  }

  /// Ouvre un sélecteur d'heure pour définir l'ouverture ou la fermeture.
  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? _openTime : _closeTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpenTime) _openTime = picked;
        else _closeTime = picked;
      });
    }
  }

  /// Enregistre les données dans Firestore (Ajout ou Mise à jour).
  Future<void> _publishTerrain() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isPublishing = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        final data = {
          'title': _nameController.text.trim(),
          'price': "${_priceController.text.trim()}£",
          'location': _locationController.text.trim(),
          'playersCount': int.parse(_playersController.text.trim()),
          'openHour': _openTime.hour,
          'openMinute': _openTime.minute,
          'closeHour': _closeTime.hour,
          'closeMinute': _closeTime.minute,
          'imagePath': widget.initialData?['imagePath'] ?? "assets/images/campo3.jpg", // Image par défaut
          'rating': widget.initialData?['rating'] ?? 5.0,
          'publisherId': user?.uid,
          'updatedAt': DateTime.now(),
        };

        if (widget.terrainId == null) {
          // Création d'un nouveau terrain
          data['createdAt'] = DateTime.now();
          await FirebaseFirestore.instance.collection('terrains').add(data);
        } else {
          // Mise à jour d'un terrain existant
          await FirebaseFirestore.instance
              .collection('terrains')
              .doc(widget.terrainId)
              .update(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Translations.translate('success_add', localeNotifier.value.languageCode)),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Retour au profil
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isPublishing = false);
      }
    }
  }

  /// Supprime définitivement le terrain de Firestore.
  Future<void> _deleteTerrain(String lang) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate('delete_terrain_title', lang)),
        content: Text(Translations.translate('delete_terrain_msg', lang)),
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
        await FirebaseFirestore.instance.collection('terrains').doc(widget.terrainId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translations.translate('delete_success', lang)), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, _) {
        final String lang = currentLocale.languageCode;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.terrainId == null 
              ? Translations.translate('add_terrain_title', lang)
              : Translations.translate('add_terrain_title', lang)),
            actions: [
              // Bouton supprimer visible uniquement en mode édition
              if (widget.terrainId != null)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTerrain(lang),
                  tooltip: Translations.translate('delete', lang),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saisie du nom
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: Translations.translate('field_name', lang),
                      prefixIcon: const Icon(Icons.sports_soccer),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 20),
                  // Saisie du prix
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: Translations.translate('field_price', lang),
                      prefixIcon: const Icon(Icons.money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 20),
                  // Saisie de l'adresse
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: Translations.translate('field_location', lang),
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 20),
                  // Saisie du nombre de joueurs
                  TextFormField(
                    controller: _playersController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: Translations.translate('field_players', lang),
                      prefixIcon: const Icon(Icons.groups),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Required";
                      if (int.tryParse(value) == null) return "Enter a number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),
                  
                  // Sélection des horaires d'ouverture/fermeture
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text(Translations.translate('open_time', lang), style: const TextStyle(fontSize: 12)),
                          subtitle: Text(_openTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.access_time, size: 20),
                          onTap: () => _selectTime(context, true),
                          shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ListTile(
                          title: Text(Translations.translate('close_time', lang), style: const TextStyle(fontSize: 12)),
                          subtitle: Text(_closeTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.access_time, size: 20),
                          onTap: () => _selectTime(context, false),
                          shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  // Bouton de validation
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isPublishing ? null : _publishTerrain,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isPublishing 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            Translations.translate('btn_publish', lang),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
