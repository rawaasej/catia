require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

// Connexion à MongoDB
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => console.log('Connecté à MongoDB')).catch((err) => console.error('Erreur de connexion MongoDB:', err));

// Modèle utilisateur
const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
});

const User = mongoose.model('User', UserSchema);

// Route d'inscription
app.post('/register', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email et mot de passe requis' });
  }

  try {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = new User({ email, password: hashedPassword });
    await newUser.save();

    res.status(201).json({ message: 'Utilisateur enregistré avec succès' });
  } catch (error) {
    if (error.code === 11000) {
      res.status(400).json({ message: 'Cet email est déjà utilisé' });
    } else {
      res.status(500).json({ message: 'Erreur serveur' });
    }
  }
});

// Route de connexion
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email et mot de passe requis' });
  }

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Mot de passe incorrect' });
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.status(200).json({ token });
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// Démarrage du serveur
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Serveur en cours d'exécution sur le port ${PORT}`));