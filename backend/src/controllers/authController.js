const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
require('dotenv').config();

// Register new user with PIN
exports.register = async (req, res) => {
  const { username, pin, email, role } = req.body;

  try {
    const hashedPin = await bcrypt.hash(pin, 10);

    const newUser = await db.query(
      'INSERT INTO users (username, pin, email, role) VALUES ($1, $2, $3, $4) RETURNING id, username, email, role',
      [username, hashedPin, email, role || 'user']
    );

    res.status(201).json(newUser.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Login using email + 4-digit PIN
exports.login = async (req, res) => {
  const { email, pin } = req.body;

  try {
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);

    if (result.rows.length === 0) {
      console.log('❌ Email not found');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = result.rows[0];
    console.log('✅ Found user:', user);

    const isValid = await bcrypt.compare(pin, user.pin);

    console.log('👉 Comparing pins:');
    console.log('Received pin:', pin);
    console.log('Hashed pin in DB:', user.pin);
    console.log('bcrypt result:', isValid);

    if (!isValid) {
      console.log('❌ Invalid PIN');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    console.log('✅ Login successful!');
    res.json({ token, role: user.role });

  } catch (err) {
    console.error('🔥 Login error:', err);
    res.status(500).json({ error: err.message });
  }
};

// Get user email from token (unchanged)
exports.getUserEmail = async (req, res) => {
  try {
    if (!req.user || !req.user.email) {
      return res.status(401).json({ error: "Unauthorized: Email missing in token" });
    }

    res.json({ email: req.user.email });
  } catch (err) {
    console.error("Error retrieving user email:", err);
    res.status(500).json({ error: "Internal server error" });
  }
};

// Get all users
exports.getAllUsers = async (req, res) => {
  try {
    const result = await db.query(
      'SELECT id, username, email, role, created_at FROM users ORDER BY created_at DESC'
    );
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};