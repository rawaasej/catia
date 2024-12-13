import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'register_chat_page.dart';

class ResultPage extends StatefulWidget {
  final File selectedFile;
  final String predictionResult;

  const ResultPage({
    Key? key,
    required this.selectedFile,
    required this.predictionResult,
  }) : super(key: key);

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late VideoPlayerController _controller;
  bool _isVideoPredictionLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedFile.path.endsWith('.mp4')) {
      _controller = VideoPlayerController.file(widget.selectedFile)
        ..initialize().then((_) {
          setState(() {
            _isVideoPredictionLoaded =
                true; // Flag set to true when video is ready
          });
        })
        ..play();
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.selectedFile.path.endsWith('.mp4')) {
      _controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat de la Prédiction'),
        backgroundColor:
            const Color.fromARGB(255, 3, 54, 4), // Set AppBar background color
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/cattt.jpg'), // Set your background image here
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Check if file is a video and display accordingly
              widget.selectedFile.path.endsWith('.mp4')
                  ? AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _controller.value.isInitialized
                          ? VideoPlayer(_controller)
                          : const Center(child: CircularProgressIndicator()),
                    )
                  : Image.file(widget.selectedFile),

              const SizedBox(height: 20),

              // Display prediction result
              Text(
                'Résultat de la Prédiction: ${widget.predictionResult}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color to contrast with background
                ),
              ),

              const SizedBox(height: 20),

              // If it's a video, display prediction for the video
              widget.selectedFile.path.endsWith('.mp4') &&
                      _isVideoPredictionLoaded
                  ? Column(
                      children: [
                        Text(
                          'Prédiction pour cette vidéo:',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 4, 69, 25),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          widget.predictionResult,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 5, 69, 31),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),

              const SizedBox(height: 20),

              // Button to navigate to RegisterChatPage
              ElevatedButton(
                onPressed: () {
                  // Navigate to the RegisterChatPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterChatPage()),
                  );
                },
                child: const Text(
                  'Enregistrer le Chat',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(
                      255, 7, 65, 15), // Button background color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
