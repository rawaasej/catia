const mongoose = require('mongoose');
const bcrypt = require('bcrypt'); // Importation de bcrypt pour le hachage

// Définition du schéma Client
const ClientSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  phone: {
    type: String,
    required: true,
  },
  password: {
    type: String,
    required: true, // Mot de passe obligatoire
  },
});

// Exportation du modèle Client
module.exports = mongoose.model('Client', ClientSchema);
