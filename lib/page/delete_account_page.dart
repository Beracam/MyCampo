import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_auth/auth.dart';
import '../main.dart';
import '../translations.dart';

/// Page de suppression de compte (Conformité RGPD).
/// Permet à un utilisateur de supprimer ses données et son accès.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Procède à la connexion puis à la suppression du compte.
  Future<void> _handleDeleteAccount(String lang) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Pour supprimer un compte, l'utilisateur doit être connecté.
        // S'il ne l'est pas (accès depuis la page Login), on le connecte.
        if (Auth().currentUser == null) {
          await Auth().loginWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          // Si déjà connecté, on ré-authentifie par sécurité.
          await Auth().reauthenticate(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        }

        // Suppression des données Firestore et du compte Auth
        await Auth().deleteAccount();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translations.translate('delete_account_confirm', lang)), backgroundColor: Colors.green),
          );
          // Retour à la racine (Page d'accueil/Login)
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Error"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(Translations.translate('delete_account_title', lang)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 80),
                  const SizedBox(height: 20),
                  Text(
                    Translations.translate('delete_account_msg', lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  
                  // Confirmation Email
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.email, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 20),

                  // Confirmation Mot de passe
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 40),

                  // Bouton Action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleDeleteAccount(lang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(Translations.translate('delete_account_btn', lang), textAlign: TextAlign.center),
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
