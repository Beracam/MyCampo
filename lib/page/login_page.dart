import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mycampo/page/signup_page.dart';
import 'package:mycampo/page/delete_account_page.dart';
import '../main.dart';
import '../translations.dart';
import '../firebase_auth/auth.dart';

/// Page de connexion de l'application.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isObscure = true;
  bool _isLoading = false;

  /// Affiche une boîte de dialogue pour envoyer un mail de réinitialisation de mot de passe.
  Future<void> _showForgotPasswordDialog(String lang) async {
    // On pré-remplit avec l'email déjà saisi si possible
    final resetEmailController = TextEditingController(text: _emailController.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate('reset_password_title', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Translations.translate('reset_password_msg', lang)),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.translate('cancel_btn', lang), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              String email = resetEmailController.text.trim();
              if (email.isEmpty) return;
              
              try {
                // On envoie directement le mail de réinitialisation sans vérifier l'existence
                // pour éviter les erreurs de permission Firestore et protéger la confidentialité.
                await Auth().sendPasswordResetEmail(email);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Translations.translate('reset_email_sent', lang)), 
                      backgroundColor: Colors.green
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(Translations.translate('reset_password_btn', lang)),
          ),
        ],
      ),
    );
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
            centerTitle: true,
            title: const Text(
              "MY Campo",
              style: TextStyle(fontSize: 40, fontFamily: 'Poppins', color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  
                  // Champ Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      labelText: "E-mail Address",
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[600],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Please enter email address";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Champ Mot de passe
                  TextFormField(
                    controller: _passwordController,
                    obscureText: isObscure,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[600],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => isObscure = !isObscure),
                        icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Please enter password";
                      return null;
                    },
                  ),
                  
                  // Lien Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotPasswordDialog(lang),
                      child: Text(
                        Translations.translate('forgot_password', lang),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Bouton Login
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          try {
                            await Auth().loginWithEmailAndPassword(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            if (mounted) Navigator.pop(context);
                          } on FirebaseAuthException catch (e) {
                            if (mounted) {
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${e.message}"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Login", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  
                  // BOUTON SUPPRIMER MON COMPTE (RGPD)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DeleteAccountPage()),
                      );
                    },
                    child: const Text(
                      "Delete MyCampo account",
                      style: TextStyle(color: Colors.redAccent, fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text("OR", textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  
                  // Bouton Sign up
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("Sign up", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
