import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'result_page.dart'; // Assurez-vous que ce fichier existe
import 'chat_list_page.dart';
import 'package:path_provider/path_provider.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();
  TextEditingController _searchController = TextEditingController();
  String chatId = '';
  VideoPlayerController? _videoController;
  String _predictionResult = ''; // Pour afficher le résultat de la prédiction
  bool _isLoading = false;
  String _imageBase64 = '';

  // Méthode pour analyser le fichier via Raspberry
  Future<void> _analyzeWithRaspberry() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.25:5000/last_analysis'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _imageBase64 = data['image'];
          _predictionResult = data['result'];
        });

        // Convertir l'image Base64 en fichier temporaire
        _selectedFile = await _writeBase64ToFile(_imageBase64);
        _navigateToResults();
      } else {
        _showSnackBar('Erreur lors de l\'analyse.');
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion : $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Méthode pour sélectionner un fichier (image ou vidéo)
  Future<void> _pickFile(ImageSource source, {bool isVideo = false}) async {
    try {
      final pickedFile = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          if (isVideo) {
            _initializeVideoPlayer(File(pickedFile.path));
          }
        });
      } else {
        _showSnackBar("Aucun fichier sélectionné.");
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la sélection du fichier : $e");
    }
  }

  // Méthode pour initialiser le lecteur vidéo
  void _initializeVideoPlayer(File videoFile) {
    _videoController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {
          _videoController?.play();
        });
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // Méthode pour capturer une vidéo directement avec la caméra
  Future<void> _recordVideo() async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _initializeVideoPlayer(File(pickedFile.path));
        });
        _showSnackBar('Vidéo capturée avec succès.');
      } else {
        _showSnackBar('Aucune vidéo capturée.');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ouverture de la caméra : $e');
    }
  }

  // Méthode pour afficher un Snackbar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Méthode pour envoyer l'image ou vidéo au modèle IA et obtenir la prédiction
  Future<void> _predictFile() async {
    if (_selectedFile == null) {
      _showSnackBar('Aucun fichier sélectionné.');
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'http://192.168.1.25:5000/predict_image'), // Utilisez predict_image pour les images
      );

      // Si c'est une vidéo, changez l'URL en /predict_video
      if (_selectedFile!.path.endsWith('.mp4')) {
        request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'http://192.168.1.25:5000/predict_video'), // Utilisez predict_video pour les vidéos
        );
      }

      request.files
          .add(await http.MultipartFile.fromPath('file', _selectedFile!.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final result = jsonDecode(responseData)['result'];

        setState(() {
          _predictionResult = result;
        });

        // Si le fichier est une vidéo, assurez-vous que le résultat s'affiche correctement
        _navigateToResults();
      } else {
        _showSnackBar('Erreur lors de la prédiction du modèle.');
      }
    } catch (e) {
      print('Erreur : $e');
      _showSnackBar('Erreur lors de la communication avec le modèle.');
    }
  }

  Future<File> _writeBase64ToFile(String base64Str) async {
    Uint8List bytes = base64Decode(base64Str);
    String dir = (await getTemporaryDirectory()).path;
    String filePath = '$dir/last_received_image.jpg';
    return File(filePath).writeAsBytes(bytes);
  }

  void _navigateToResults() {
    if (_selectedFile != null && _predictionResult.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            selectedFile: _selectedFile!,
            predictionResult: _predictionResult,
          ),
        ),
      );
    } else {
      _showSnackBar(
          'Aucun fichier sélectionné ou résultat de prédiction manquant.');
    }
  }

  // Recherche un chat par ID
  Future<void> _searchChatById() async {
    final chatId = _searchController.text.trim();
    if (chatId.isEmpty) {
      _showSnackBar('Veuillez entrer un ID de chat.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.25:3090/chats/$chatId'),
      );

      if (response.statusCode == 200) {
        final List chatData = jsonDecode(response.body);
        if (chatData.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aucun chat trouvé pour cet ID')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chats trouvés: ${chatData.length}')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatListPage(chats: chatData),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la récupération des chats')),
        );
      }
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche du chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Utilisateur'),
        backgroundColor: const Color.fromARGB(255, 2, 56, 17),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bouuu.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bienvenue, Utilisateur!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, color: Color.fromARGB(255, 8, 91, 31)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher un chat par ID',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) => _searchChatById(),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _pickFile(ImageSource.gallery),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color.fromARGB(255, 2, 51, 13)),
                  ),
                  child: _selectedFile == null
                      ? const Center(
                          child: Text(
                            'Appuyez pour sélectionner une image',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.teal),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _selectedFile!.path.endsWith('.mp4')
                              ? _videoController != null &&
                                      _videoController!.value.isInitialized
                                  ? AspectRatio(
                                      aspectRatio:
                                          _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    )
                              : Image.file(
                                  _selectedFile!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 2, 49, 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                    ),
                    onPressed: () => _pickFile(ImageSource.camera),
                    child: const Text('Prendre une Photo'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 2, 49, 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                    ),
                    onPressed: () =>
                        _pickFile(ImageSource.gallery, isVideo: true),
                    child: const Text('Insérer une vidéo'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 2, 49, 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                    ),
                    onPressed: _recordVideo,
                    child: const Text('Enregistrer une vidéo'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 2, 49, 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                ),
                onPressed: _analyzeWithRaspberry,
                child: const Text('Analyser avec Raspberry'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
               
                  backgroundColor: const Color.fromARGB(255, 2, 49, 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                ),
                onPressed: _predictFile,
                child: const Text('confirmer'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 2, 56, 17),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                ),
                onPressed: () {
                  // Action pour un autre bouton, par exemple, retour à l'écran principal
                  Navigator.pop(context);
                },
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
