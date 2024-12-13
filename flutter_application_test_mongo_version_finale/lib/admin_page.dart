import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminHome extends StatefulWidget {
  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  List clients = [];
  TextEditingController _emailController = TextEditingController();

  // Ne plus charger les clients au démarrage
  @override
  void initState() {
    super.initState();
  }

  // Récupérer tous les clients (seulement après avoir cliqué sur le bouton)
  Future<void> fetchClients() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.1.25:3090/clients'));
      if (response.statusCode == 200) {
        setState(() {
          clients = jsonDecode(response.body);
        });
      } else {
        throw Exception('Erreur lors de la récupération des données');
      }
    } catch (e) {
      print('Erreur : $e');
    }
  }

  // Recherche un client par email
  Future<void> searchClientByEmail(String email) async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.1.25:3090/clientsmail?email=$email'));
      if (response.statusCode == 200) {
        setState(() {
          clients = jsonDecode(response.body);
        });
      } else {
        setState(() {
          clients = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aucun client trouvé pour cet email')),
        );
      }
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche du client')),
      );
    }
  }

  // Ajouter un client
  Future<void> addClient(
      String name, String email, String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.25:3090/clients'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          clients.add(jsonDecode(response.body));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Client ajouté avec succès !')),
        );
      } else {
        throw Exception('Erreur lors de l\'ajout du client');
      }
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout du client')),
      );
    }
  }

  // Supprimer un client
  Future<void> deleteClient(String id) async {
    try {
      final response =
          await http.delete(Uri.parse('http://192.168.1.25:3090/clients/$id'));
      if (response.statusCode == 200) {
        setState(() {
          clients.removeWhere((client) => client['_id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Client supprimé avec succès !')),
        );
      } else {
        throw Exception('Erreur lors de la suppression du client');
      }
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression du client')),
      );
    }
  }

  // Modifier un client
  Future<void> updateClient(String id, String name, String email, String phone,
      String password) async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.1.25:3090/clients/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        fetchClients(); // Recharger les clients
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Client modifié avec succès !')),
        );
      } else {
        throw Exception('Erreur lors de la modification du client');
      }
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification du client')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Clients'),
        backgroundColor: const Color.fromARGB(255, 26, 75, 28),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/chatasma.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Rechercher par Email',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        searchClientByEmail(_emailController.text);
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Ne pas afficher les clients immédiatement
              clients.isEmpty
                  ? Center(child: Text('Aucun client à afficher'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return Card(
                          child: ListTile(
                            title: Text(client['name']),
                            subtitle: Text(client['email']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color:
                                          const Color.fromARGB(255, 2, 46, 15)),
                                  onPressed: () {
                                    _showEditClientDialog(
                                      client['_id'],
                                      client['name'],
                                      client['email'],
                                      client['phone'],
                                      client['password'],
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Color.fromARGB(255, 9, 81, 18)),
                                  onPressed: () {
                                    deleteClient(client['_id']);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: fetchClients, // Afficher tous les clients
                      child: Text('Afficher tous les clients'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showAddClientDialog();
                      },
                      child: Text('Ajouter un client'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ajouter un client via un dialogue
  void _showAddClientDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '', email = '', phone = '', password = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un client'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nom'),
                  onChanged: (value) => name = value,
                  validator: (value) =>
                      value!.isEmpty ? 'Le nom est requis' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email'),
                  onChanged: (value) => email = value,
                  validator: (value) =>
                      value!.isEmpty ? 'L\'email est requis' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Téléphone'),
                  onChanged: (value) => phone = value,
                  validator: (value) =>
                      value!.isEmpty ? 'Le téléphone est requis' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Mot de passe'),
                  onChanged: (value) => password = value,
                  validator: (value) =>
                      value!.isEmpty ? 'Le mot de passe est requis' : null,
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                addClient(name, email, phone, password);
                Navigator.pop(context);
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // Modifier un client via un dialogue
  void _showEditClientDialog(
      String id, String name, String email, String phone, String password) {
    final _formKey = GlobalKey<FormState>();
    String newName = name,
        newEmail = email,
        newPhone = phone,
        newPassword = password;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier un client'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: InputDecoration(labelText: 'Nom'),
                  onChanged: (value) => newName = value,
                ),
                TextFormField(
                  initialValue: email,
                  decoration: InputDecoration(labelText: 'Email'),
                  onChanged: (value) => newEmail = value,
                ),
                TextFormField(
                  initialValue: phone,
                  decoration: InputDecoration(labelText: 'Téléphone'),
                  onChanged: (value) => newPhone = value,
                ),
                TextFormField(
                  initialValue: password,
                  decoration: InputDecoration(labelText: 'Mot de passe'),
                  onChanged: (value) => newPassword = value,
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              updateClient(id, newName, newEmail, newPhone, newPassword);
              Navigator.pop(context);
            },
            child: Text('Modifier'),
          ),
        ],
      ),
    );
  }
}
