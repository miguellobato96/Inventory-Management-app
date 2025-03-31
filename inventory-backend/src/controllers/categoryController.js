const pool = require('../config/db');

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

// Update a category
exports.updateCategory = async (req, res) => {
    const { id } = req.params;
    const { name } = req.body;
    try {
        const result = await pool.query(
            'UPDATE categories SET name = $1 WHERE id = $2 RETURNING *',
            [name, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Categoria não encontrada' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Erro ao atualizar categoria:', err);
        res.status(500).json({ error: 'Erro ao atualizar categoria' });
    }
};

// Delete a category
exports.deleteCategory = async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query(
            'DELETE FROM categories WHERE id = $1 RETURNING *',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Categoria não encontrada' });
        }

        res.json({ message: 'Categoria eliminada com sucesso' });
    } catch (err) {
        console.error('Erro ao eliminar categoria:', err);
        res.status(500).json({ error: 'Erro ao eliminar categoria' });
    }
};
