const pool = require('../config/db');

// Add a new category
exports.createCategory = async (req, res) => {
    const { name, parent_id } = req.body;
    try {
        const result = await pool.query(
            'INSERT INTO categories (name, parent_id) VALUES ($1, $2) RETURNING *',
            [name, parent_id || null]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error('Error adding category:', err);
        res.status(500).json({ error: 'Failed to add category' });
    }
};

// Get main categories
exports.getMainCategories = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT id, name 
            FROM categories 
            WHERE parent_id IS NULL
            ORDER BY name ASC;
        `);
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching main categories:', err);
        res.status(500).json({ error: 'Failed to fetch main categories' });
    }
};

// Get subcategories for a given category
exports.getSubcategories = async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query(`
            SELECT id, name FROM categories 
            WHERE parent_id = $1 
            ORDER BY name ASC
        `, [id]);

        if (result.rows.length === 0) {
            return res.json({ message: "No subcategories found." });
        }

        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching subcategories:', err);
        res.status(500).json({ error: 'Failed to fetch subcategories' });
    }
};
