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

// Update an existing location
exports.updateLocation = async (req, res) => {
    const { id } = req.params;
    const { name } = req.body;

    try {
        const result = await pool.query(
            'UPDATE locations SET name = $1 WHERE id = $2 RETURNING *',
            [name, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Location not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error updating location:', err);
        res.status(500).json({ error: 'Failed to update location' });
    }
};

// Delete a location
exports.deleteLocation = async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query(
            'DELETE FROM locations WHERE id = $1 RETURNING *',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Location not found' });
        }

        res.json({ message: 'Location deleted successfully' });
    } catch (err) {
        console.error('Error deleting location:', err);
        res.status(500).json({ error: 'Failed to delete location' });
    }
};
