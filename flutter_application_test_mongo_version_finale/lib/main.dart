import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_page.dart'; // Page Admin
import 'user_page.dart'; // Page Utilisateur

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Détection de maladies chez les chats',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Fonction de connexion
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Vérification des identifiants admin
    if (email == 'asmaiot384@gmail.com' && password == 'adminpassword') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminHome()),
      );
    } else {
      try {
        final response = await http.post(
          Uri.parse('http://192.168.1.25:3090/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

        if (response.statusCode == 200) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const  UserPage()),
          );
        } else {
          _showSnackBar('Identifiants invalides. Veuillez réessayer.');
        }
        
      } catch (e) {
        _showSnackBar('Erreur de connexion : $e');
      }
    }
  }

  // Fonction pour afficher les messages d'erreur
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('bienvenue a notre application detchat'),
        backgroundColor: const Color.fromARGB(
            255, 26, 75, 28), // Couleur verte pour l'AppBar
      ),
      body: AnimatedBackground(
        // Animated background inside the Scaffold body
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.1,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Adresse email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email.';
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(value)) {
                      return 'Veuillez entrer un email valide.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe.';
                    } else if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: login,
                  child: const Text('Se connecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        255, 26, 75, 28), // Couleur de fond verte
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({Key? key, required this.child}) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0.05),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: SlideTransition(
                position: _animation,
                child: Image.asset(
                  'assets/images/a.jpg', // Vérifiez le chemin de l'image
                  fit: BoxFit.cover,
                ),
              ),
            ),
            widget
                .child, // Your login form is stacked on top of the animated background
          ],
        );
      },
    );
  }
}
