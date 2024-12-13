import 'package:flutter/material.dart';

class ChatListPage extends StatelessWidget {
  final List chats;

  const ChatListPage({Key? key, required this.chats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Chats'),
        backgroundColor: const Color.fromARGB(255, 2, 56, 17),
      ),
      body: chats.isEmpty
          ? const Center(
              child: Text('Aucun chat trouvé'),
            )
          : ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                var chat = chats[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text('Chat ID: ${chat['id']}'),
                    subtitle: Text('Date: ${chat['date']}'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // Logique pour naviguer ou afficher les détails d'un chat
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Chat ID: ${chat['id']}'),
                            content: Text('Date: ${chat['date']}'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
