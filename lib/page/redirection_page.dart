import 'package:flutter/material.dart';
import '../firebase_auth/auth.dart';
import 'package:mycampo/page/event_page.dart';
import 'home_page.dart';

/// Page de redirection
/// Elle écoute l'état d'authentification de Firebase pour décider quelle page afficher au démarrage.
class RedirectionPage extends StatefulWidget{
  const RedirectionPage({super.key});

  @override
  State<StatefulWidget> createState(){
    return _RedirectionPageState();
  }
}

class _RedirectionPageState extends State<RedirectionPage>{

  @override
  Widget build(BuildContext context){
    // StreamBuilder écoute le flux 'authStateChange' défini dans le service Auth
    return StreamBuilder(
        stream: Auth().authStateChange,
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) { // Si en attente de données, on affiche un indicateur de chargement
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()), // Affiche un indicateur de chargement
            );
          }

          // Si snapshot contient des données, cela signifie que l'utilisateur est connecté
          if (snapshot.hasData) {
            // On le dirige vers la page principale de l'application
            return const EventPage(title: "EventPage");
          }

          // Si aucune donnée n'est présente, l'utilisateur n'est pas connecté
          // On affiche alors la page de présentation/accueil
          return const HomePage();
        },
    );
  }
}