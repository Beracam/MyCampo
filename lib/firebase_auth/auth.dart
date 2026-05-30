import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Classe de service gérant toutes les interactions avec Firebase Authentication et Firestore.
class Auth {
  // Instance de Firebase Authentication
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // Instance de Cloud Firestore pour la base de données
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupère l'utilisateur actuellement connecté (peut être nul)
  User? get currentUser => _firebaseAuth.currentUser;
  
  // Stream permettant d'écouter les changements d'état (connexion/déconnexion)
  Stream<User?> get authStateChange => _firebaseAuth.authStateChanges();

  /// Connecte un utilisateur existant avec son email et mot de passe.
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Déconnecte l'utilisateur actuel.
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  /// Crée un nouveau compte et enregistre les informations de profil dans Firestore.
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String pseudo,
    required String phone,
  }) async {
    // 1. Création du compte technique dans Firebase Auth
    UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Création du document profil dans la collection 'users' avec l'UID du compte
    if (userCredential.user != null) {
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'pseudo': pseudo,
        'phone': phone,
        'email': email,
        'createdAt': DateTime.now(), // Date de création pour le suivi
      });
    }
  }
}
