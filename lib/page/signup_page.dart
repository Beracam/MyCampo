import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../firebase_auth/auth.dart';
import '../main.dart';
import '../translations.dart';

/// Page d'inscription (Sign Up) de l'application.
/// Permet à un nouvel utilisateur de créer un compte avec Pseudo, Téléphone, Email et Mot de passe.
/// Inclut également l'acceptation des conditions d'utilisation et de la politique de confidentialité.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Clé globale pour la validation du formulaire
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour récupérer les saisies utilisateur
  final _pseudoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // État pour masquer/afficher le mot de passe
  bool isObscure = true;
  // État de chargement pendant la création du compte
  bool _isLoading = false;

  // ÉTATS POUR LES CASES À COCHER (RGPD / CONDITIONS)
  bool _acceptTerms = false;
  bool _acceptDataManage = false;

  @override
  void dispose() {
    // Libère les contrôleurs lorsque la page est fermée pour éviter les fuites de mémoire
    _pseudoController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Affiche une boîte de dialogue contenant l'intégralité des conditions d'utilisation.
  void _showTermsDialog(String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate('terms_title', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            Translations.translate('terms_body', lang),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.translate('read_understand', lang)),
          ),
        ],
      ),
    );
  }

  /// Affiche une boîte de dialogue contenant la politique de confidentialité.
  void _showPrivacyPolicyDialog(String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate('privacy_title', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            Translations.translate('privacy_body', lang),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.translate('read_understand', lang)),
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
          backgroundColor: Colors.black, // Design sombre cohérent avec la connexion
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
                  const SizedBox(height: 20),
                  
                  // Champ Pseudo
                  _buildTextField(_pseudoController, "Pseudo", Icons.person),
                  const SizedBox(height: 20),

                  // Champ Téléphone
                  _buildTextField(_phoneController, "Téléphone", Icons.phone, type: TextInputType.phone),
                  const SizedBox(height: 20),

                  // Champ Email
                  _buildTextField(_emailController, "E-mail", Icons.email, type: TextInputType.emailAddress),
                  const SizedBox(height: 20),

                  // Champ Mot de passe
                  _buildTextField(_passwordController, "Mot de passe", Icons.lock, isPass: true),
                  const SizedBox(height: 20),

                  // Confirmation du Mot de passe
                  _buildTextField(_confirmPasswordController, "Confirmer mot de passe", Icons.lock_reset, isPass: true, isConfirm: true),
                  
                  const SizedBox(height: 20),

                  // CASE À COCHER : CONDITIONS D'UTILISATION (Lien cliquable vers le dialogue)
                  Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.white70),
                    child: CheckboxListTile(
                      value: _acceptTerms,
                      onChanged: (val) => setState(() => _acceptTerms = val!),
                      title: InkWell(
                        onTap: () => _showTermsDialog(lang),
                        child: Text(
                          Translations.translate('terms_accept', lang),
                          style: const TextStyle(
                            color: Colors.white70, 
                            fontSize: 13, 
                            decoration: TextDecoration.underline
                          ),
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.red,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  // CASE À COCHER : GESTION DES DONNÉES (Politique de Confidentialité cliquable)
                  Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.white70),
                    child: CheckboxListTile(
                      value: _acceptDataManage,
                      onChanged: (val) => setState(() => _acceptDataManage = val!),
                      title: InkWell(
                        onTap: () => _showPrivacyPolicyDialog(lang),
                        child: Text(
                          Translations.translate('data_manage_accept', lang),
                          style: const TextStyle(
                            color: Colors.white70, 
                            fontSize: 13, 
                            decoration: TextDecoration.underline
                          ),
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.red,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bouton pour valider l'inscription
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleSignup(lang),
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
      },
    );
  }

  /// Helper pour construire le style des champs de texte de manière centralisée
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text, bool isPass = false, bool isConfirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass ? isObscure : false,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[600],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0), borderSide: BorderSide.none),
        suffixIcon: isPass ? IconButton(
          onPressed: () => setState(() => isObscure = !isObscure),
          icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off, color: Colors.white),
        ) : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Champs requis";
        if (isConfirm && value != _passwordController.text) return "Les mots de passe diffèrent";
        // Validation spécifique pour le téléphone
        if (label == "Téléphone" && !RegExp(r'^\+?\d{7,15}$').hasMatch(value)) return "Numéro invalide";
        // Validation spécifique pour l'email
        if (label == "E-mail" && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return "Email invalide";
        return null;
      },
    );
  }

  /// Gère la logique d'inscription après vérification des consentements obligatoires.
  Future<void> _handleSignup(String lang) async {
    // Vérification stricte des cases à cocher avant de procéder à l'inscription
    if (!_acceptTerms || !_acceptDataManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.translate('terms_error', lang)), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Création du compte via le service Auth (Auth + Firestore)
        await Auth().createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          pseudo: _pseudoController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        if (mounted) {
          Navigator.pop(context); // Retour à la connexion ou redirection automatique
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
