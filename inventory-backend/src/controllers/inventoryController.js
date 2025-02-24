const db = require('../config/db');

// Create Item
exports.createItem = async (req, res) => {
  const io = req.app.get('socketio');
  const { name, category, quantity } = req.body;
  try {
    const newItem = await db.query(
      'INSERT INTO inventory (name, category, quantity) VALUES ($1, $2, $3) RETURNING *',
      [name, category, quantity]
    );
    
    io.emit('inventory-updated'); // Emit clearly after adding
    res.status(201).json(newItem.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get All Items
exports.getItems = async (req, res) => {
  try {
    const items = await db.query('SELECT * FROM inventory');
    res.json(items.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get Single Item by ID
exports.getItemById = async (req, res) => {
  const { id } = req.params;
  try {
    const item = await db.query('SELECT * FROM inventory WHERE id = $1', [id]);
    res.json(item.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Update Item
exports.updateItem = async (req, res) => {
  const io = req.app.get('socketio');
  const { id } = req.params;
  const { name, category, quantity } = req.body;
  try {
    const updated = await db.query(
      'UPDATE inventory SET name=$1, category=$2, quantity=$3, updated_at=CURRENT_TIMESTAMP WHERE id=$4 RETURNING *',
      [name, category, quantity, id]
    );
    
    io.emit('inventory-updated'); // Emit clearly after updating
    res.json(updated.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Delete Item
exports.deleteItem = async (req, res) => {
  const io = req.app.get('socketio');
  const { id } = req.params;
  try {
    await db.query('DELETE FROM inventory WHERE id=$1', [id]);
    
    io.emit('inventory-updated'); // Emit clearly after deletion
    res.status(204).json({ message: 'Item deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
