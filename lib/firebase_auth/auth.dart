import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service gérant les interactions avec Firebase Authentication et Cloud Firestore.
class Auth {
  // Instance de Firebase Authentication pour la gestion des comptes
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // Instance de Cloud Firestore pour le stockage des données utilisateurs
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupère l'utilisateur actuellement connecté
  User? get currentUser => _firebaseAuth.currentUser;

  // Flux (Stream) permettant de suivre l'état de connexion de l'utilisateur en temps réel
  Stream<User?> get authStateChange => _firebaseAuth.authStateChanges();

  /// Vérifie si une adresse email est déjà enregistrée dans la collection 'users' de Firestore.
  Future<bool> checkEmailExists(String email) async {
    final result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  /// Envoie un email automatique de Firebase pour permettre à l'utilisateur de réinitialiser son mot de passe.
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Authentifie un utilisateur avec son email et son mot de passe.
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Déconnecte l'utilisateur de la session actuelle.
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  /// Supprime définitivement le compte de l'utilisateur actuel et TOUTES ses données associées (RGPD).
  /// Cela inclut son profil, ses publications de terrains et ses réservations.
  Future<void> deleteAccount() async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      String uid = user.uid;
      WriteBatch batch = _firestore.batch();

      // 1. Récupère et prépare la suppression des TERRAINS publiés par l'utilisateur
      var terrains = await _firestore.collection('terrains')
          .where('publisherId', isEqualTo: uid).get();
      
      for (var doc in terrains.docs) {
        batch.delete(doc.reference);
        
        // Supprime également toutes les RÉSERVATIONS liées à ces terrains
        var resOnMyTerrains = await _firestore.collection('reservations')
            .where('terrainId', isEqualTo: doc.id).get();
        for (var resDoc in resOnMyTerrains.docs) {
          batch.delete(resDoc.reference);
        }
      }

      // 2. Récupère et prépare la suppression des RÉSERVATIONS faites par l'utilisateur sur d'autres terrains
      var myReservations = await _firestore.collection('reservations')
          .where('userId', isEqualTo: uid).get();
      for (var doc in myReservations.docs) {
        batch.delete(doc.reference);
      }

      // 3. Supprime le document de profil de l'utilisateur
      batch.delete(_firestore.collection('users').doc(uid));

      // Exécute toutes les suppressions Firestore en une seule transaction atomique
      await batch.commit();

      // 4. Enfin, supprime l'utilisateur de Firebase Authentication
      await user.delete();
    }
  }

  /// Ré-authentifie l'utilisateur (requis par Firebase pour les opérations sensibles comme la suppression de compte).
  Future<void> reauthenticate(String email, String password) async {
    User? user = _firebaseAuth.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
    }
  }

  /// Crée un nouveau compte utilisateur dans Firebase Auth.
  /// En cas de succès, crée également un document dans la collection 'users' de Firestore.
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String pseudo,
    required String phone,
  }) async {
    // 1. Tentative de création du compte technique dans Firebase Auth
    UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Si le compte est créé, on stocke les informations de profil (pseudo, tel) dans Firestore
    if (userCredential.user != null) {
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'pseudo': pseudo,
        'phone': phone,
        'email': email,
        'createdAt': DateTime.now(), // Date de création du profil
      });
    }
  }
}
