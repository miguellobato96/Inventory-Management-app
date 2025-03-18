const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
require('dotenv').config();

exports.register = async (req, res) => {
  const { username, password, email, role } = req.body; // Accept role in request
  const hashedPassword = await bcrypt.hash(password, 10);

  try {
    const newUser = await db.query(
      'INSERT INTO users (username, password, email, role) VALUES ($1, $2, $3, $4) RETURNING id, username, email, role',
      [username, hashedPassword, email, role || 'user'] // Default role is "user"
    );

    res.status(201).json(newUser.rows[0]); // Return user data with role
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await db.query('SELECT * FROM users WHERE email = $1', [email]);

    if (user.rows.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' }); // User not found
    }

    const validPassword = await bcrypt.compare(password, user.rows[0].password);
    if (!validPassword) {
      return res.status(401).json({ message: 'Invalid credentials' }); // Incorrect password
    }

    // Generate JWT with user data
    const token = jwt.sign(
    { id: user.rows[0].id, username: user.rows[0].username, email: user.rows[0].email, role: user.rows[0].role },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
);

    res.json({ token, role: user.rows[0].role });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

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