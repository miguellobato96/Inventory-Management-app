const pool = require('../config/db');

// Get all users
exports.getAllUsers = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, username, email, role, created_at FROM users ORDER BY created_at DESC'
    );
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Get history for a specific user
exports.getUserHistory = async (req, res) => {
  const userId = req.params.id;
  try {
    const result = await pool.query(
      `SELECT ih.id, i.name AS item_name, ih.quantity_before, ih.quantity_change, ih.quantity_after, ih.changed_at
       FROM inventory_history ih
       JOIN inventory i ON ih.item_id = i.id
       WHERE ih.user_id = $1
       ORDER BY ih.changed_at DESC`,
      [userId]
    );
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching user history:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Create new user
exports.createUser = async (req, res) => {
  const { username, email, password, role } = req.body;

  // TODO: Add validation & password hashing if not done already
  try {
    const result = await pool.query(
      `INSERT INTO users (username, email, password, role)
       VALUES ($1, $2, $3, $4)
       RETURNING id, username, email, role, created_at`,
      [username, email, password, role || 'user']
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Update existing user
exports.updateUser = async (req, res) => {
  const userId = req.params.id;
  const { username, email, role } = req.body;

  try {
    const result = await pool.query(
      `UPDATE users
       SET username = $1, email = $2, role = $3
       WHERE id = $4
       RETURNING id, username, email, role, created_at`,
      [username, email, role, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Delete user
exports.deleteUser = async (req, res) => {
  const userId = req.params.id;

  try {
    const result = await pool.query(
      `DELETE FROM users WHERE id = $1 RETURNING id, username`,
      [userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({ message: 'User deleted', user: result.rows[0] });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};