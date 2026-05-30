import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../firebase_auth/auth.dart';

/// Page d'inscription permettant de créer un nouveau compte utilisateur.
/// Recueille le pseudo, le téléphone, l'email et le mot de passe.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Clé pour la validation du formulaire d'inscription
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs de saisie
  final _pseudoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool isObscure = true; // Pour masquer le mot de passe
  bool _isLoading = false; // Pour afficher l'indicateur de chargement

  @override
  void dispose() {
    // Libération des ressources
    _pseudoController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Inscription",
          style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              
              // Champ Pseudo
              TextFormField(
                controller: _pseudoController,
                decoration: _buildInputDecoration("Pseudo", Icons.person),
                style: const TextStyle(color: Colors.white),
                validator: (value) => value == null || value.isEmpty ? "Entrez un pseudo" : null,
              ),
              const SizedBox(height: 20),

              // Champ Téléphone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration("Téléphone", Icons.phone),
                style: const TextStyle(color: Colors.white),
                validator: (value) => value == null || value.isEmpty ? "Entrez votre numéro" : null,
              ),
              const SizedBox(height: 20),

              // Champ Email
              TextFormField(
                controller: _emailController,
                decoration: _buildInputDecoration("E-mail", Icons.email),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Entrez un email";
                  // Vérification simple du format email via Regex
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return "Email invalide";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Champ Mot de passe
              TextFormField(
                controller: _passwordController,
                obscureText: isObscure,
                decoration: _buildInputDecoration("Mot de passe", Icons.lock, isPassword: true),
                style: const TextStyle(color: Colors.white),
                validator: (value) => value != null && value.length < 6 ? "Minimum 6 caractères" : null,
              ),
              const SizedBox(height: 20),

              // Confirmation du Mot de passe
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: isObscure,
                decoration: _buildInputDecoration("Confirmer mot de passe", Icons.lock_reset),
                style: const TextStyle(color: Colors.white),
                validator: (value) => value != _passwordController.text ? "Les mots de passe diffèrent" : null,
              ),
              const SizedBox(height: 30),

              // Bouton S'inscrire
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("S'inscrire", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper pour centraliser le design des champs de saisie
  InputDecoration _buildInputDecoration(String label, IconData icon, {bool isPassword = false}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.grey[600],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0), borderSide: BorderSide.none),
      suffixIcon: isPassword 
        ? IconButton(
            onPressed: () => setState(() => isObscure = !isObscure),
            icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off, color: Colors.white),
          ) 
        : null,
    );
  }

  /// Gère l'appel au service d'authentification
  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await Auth().createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          pseudo: _pseudoController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Compte créé avec succès !"), backgroundColor: Colors.green),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Erreur d'inscription"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
