const pool = require('../config/db');

// Create new item
exports.createItem = async (req, res) => {
  const { name, quantity, low_stock_threshold, category_id, location_id } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO inventory (name, quantity, low_stock_threshold, category_id, location_id)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [name, quantity, low_stock_threshold, category_id, location_id]
    );

    res.status(201).json({ item: result.rows[0], message: 'Item criado com sucesso' });
  } catch (err) {
    console.error('Erro ao criar item:', err);
    res.status(500).json({ error: 'Erro ao criar item' });
  }
};

// Update item
exports.updateItem = async (req, res) => {
  const { id } = req.params;
  const { name, quantity, low_stock_threshold, category_id, location_id } = req.body;

  try {
    const result = await pool.query(
      `UPDATE inventory
       SET name = $1,
           quantity = $2,
           low_stock_threshold = $3,
           category_id = $4,
           location_id = $5,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $6
       RETURNING *`,
      [name, quantity, low_stock_threshold, category_id, location_id, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Item não encontrado." });
    }

    res.json({ item: result.rows[0], message: "Item atualizado com sucesso." });
  } catch (err) {
    console.error("❌ Erro ao atualizar item:", err);
    res.status(500).json({ error: "Erro ao atualizar item." });
  }
};

// Delete item
exports.deleteItem = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM inventory WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Item não encontrado." });
    }

    res.json({ message: "Item eliminado com sucesso." });
  } catch (err) {
    console.error("❌ Erro ao eliminar item:", err);
    res.status(500).json({ error: "Erro ao eliminar item." });
  }
};
