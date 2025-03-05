const pool = require('../config/db');

// Get all locations
exports.getLocations = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM locations ORDER BY name;');
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching locations:', err);
        res.status(500).json({ error: 'Failed to fetch locations' });
    }
};

// Add a new location
exports.createLocation = async (req, res) => {
    const { name } = req.body;
    try {
        const result = await pool.query(
            'INSERT INTO locations (name) VALUES ($1) RETURNING *',
            [name]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error('Error adding location:', err);
        res.status(500).json({ error: 'Failed to add location' });
    }
};
