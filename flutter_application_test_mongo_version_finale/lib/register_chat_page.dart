import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RegisterChatPage extends StatefulWidget {
  const RegisterChatPage({Key? key}) : super(key: key);

  @override
  _RegisterChatPageState createState() => _RegisterChatPageState();
}

class _RegisterChatPageState extends State<RegisterChatPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _catIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _predictionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false; // Flag to show loading state

  // Méthode pour sélectionner une image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Méthode pour soumettre le formulaire
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true; // Start loading
    });

    final catId = _catIdController.text;
    final name = _nameController.text;
    final predictionResult = _predictionController.text;
    final imageUrl = await _uploadImage(_selectedImage!);

    final response = await http.post(
      Uri.parse('http://192.168.1.25:3090/chats'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'catId': catId,
        'name': name,
        'predictionResult': predictionResult,
        'imageUrl': imageUrl,
      }),
    );

    setState(() {
      _isLoading = false; // Stop loading
    });

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Chat enregistré avec succès!'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: ${response.body}'),
      ));
    }
  }

  // Méthode pour uploader l'image
  Future<String> _uploadImage(File image) async {
    // Ici vous pouvez implémenter la logique pour uploader l'image vers un serveur ou obtenir une URL.
    // Pour cette démonstration, on retourne un chemin fictif.
    return 'https://example.com/image.jpg'; // Changez cela avec l'URL réelle de l'image.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer un Chat'),
        backgroundColor: const Color.fromARGB(255, 6, 57, 28),
      ),
      body: AnimatedContainer(
        duration: Duration(seconds: 1),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/seeee.jpg'), // Remplacez par l'image de votre choix
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _catIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID du Chat',
                    prefixIcon: Icon(Icons.pets),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un ID';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du Chat',
                    prefixIcon: Icon(Icons.catching_pokemon),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _predictionController,
                  decoration: const InputDecoration(
                    labelText: 'Résultat de la prédiction',
                    prefixIcon: Icon(Icons.lightbulb),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un résultat';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _selectedImage == null
                    ? ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Choisir une image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Color.fromARGB(255, 6, 57, 28), // Couleur de fond
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      )
                    : Image.file(
                        _selectedImage!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer le Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Color.fromARGB(255, 6, 57, 28), // Couleur de fond
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontSize: 18),
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
