// controllers/unitController.js
const pool = require('../config/db');

exports.getUserUnits = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      'SELECT id, name FROM units WHERE user_id = $1 ORDER BY name ASC',
      [userId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching user units:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.createUnit = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name } = req.body;

    const result = await pool.query(
      'INSERT INTO units (name, user_id) VALUES ($1, $2) RETURNING *',
      [name, userId]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating unit:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.updateUnit = async (req, res) => {
  try {
    const userId = req.user.id;
    const unitId = req.params.id;
    const { name } = req.body;

    const result = await pool.query(
      'UPDATE units SET name = $1 WHERE id = $2 AND user_id = $3 RETURNING *',
      [name, unitId, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Unit not found or not authorized' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating unit:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.deleteUnit = async (req, res) => {
  try {
    const userId = req.user.id;
    const unitId = req.params.id;

    const result = await pool.query(
      'DELETE FROM units WHERE id = $1 AND user_id = $2 RETURNING *',
      [unitId, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Unit not found or not authorized' });
    }

    res.json({ message: 'Unit deleted successfully' });
  } catch (err) {
    console.error('Error deleting unit:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.getUserUnitLifts = async (req, res) => {
  try {
    const userId = req.user.id;
    const unitId = req.params.id;

    const result = await pool.query(
      `SELECT ul.id AS lift_id, ul.created_at, ul.status, ul.returned_at, ul.unit_id
       FROM unit_lifts ul
       WHERE ul.unit_id = $1 AND ul.user_id = $2
       ORDER BY ul.created_at DESC`,
      [unitId, userId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching unit lifts:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};