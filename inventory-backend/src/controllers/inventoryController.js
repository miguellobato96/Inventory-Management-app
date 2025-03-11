const pool = require('../config/db');

// Create Item
exports.createItem = async (req, res) => {
    const io = req.app.get('socketio');
    const { name, category_id, quantity, location_id } = req.body;

    console.log("🔍 Received POST request:", req.body); // Log request data

    try {
        // Check if category_id exists
        const categoryCheck = await pool.query('SELECT id FROM categories WHERE id = $1', [category_id]);
        if (categoryCheck.rows.length === 0) {
            console.error("❌ Invalid category_id:", category_id);
            return res.status(400).json({ error: "Invalid category_id: Category does not exist" });
        }

        // Check if location_id exists
        const locationCheck = await pool.query('SELECT id FROM locations WHERE id = $1', [location_id]);
        if (locationCheck.rows.length === 0) {
            console.error("❌ Invalid location_id:", location_id);
            return res.status(400).json({ error: "Invalid location_id: Location does not exist" });
        }

        // Insert item
        console.log("✅ Inserting item into inventory...");
        const newItem = await pool.query(
            'INSERT INTO inventory (name, category_id, quantity, location_id) VALUES ($1, $2, $3, $4) RETURNING *',
            [name, category_id, quantity, location_id]
        );

        console.log("✅ Item inserted successfully:", newItem.rows[0]);
        io.emit('inventory-updated');
        res.status(201).json(newItem.rows[0]);
    } catch (err) {
        console.error('❌ Error inserting item:', err.stack);
        res.status(500).json({ error: err.message });
    }
};

// Get All Items
exports.getItems = async (req, res) => {
    try {
        console.log("🔍 Fetching inventory...");

        const result = await pool.query(`
            WITH RECURSIVE category_tree AS (
                SELECT id FROM categories
                UNION ALL
                SELECT c.id FROM categories c
                INNER JOIN category_tree ct ON c.parent_id = ct.id
            )
            SELECT 
                inventory.id, 
                inventory.name, 
                inventory.category_id,  
                COALESCE(categories.name, 'Sem Categoria') AS category, 
                inventory.quantity, 
                inventory.location_id, 
                COALESCE(locations.name, 'Não Atribuído') AS location_name
            FROM inventory
            LEFT JOIN locations ON inventory.location_id = locations.id
            LEFT JOIN categories ON inventory.category_id = categories.id
            WHERE inventory.category_id IN (SELECT id FROM category_tree) 
               OR inventory.category_id IS NULL -- ✅ Inclui também itens sem categoria
            ORDER BY inventory.name ASC;
        `);

        console.log("✅ Inventory fetched successfully! Total items:", result.rows.length);
        res.json(result.rows);
    } catch (err) {
        console.error('❌ Error fetching inventory:', err.stack);
        res.status(500).json({ error: err.message });
    }
};

// Get Single Item by ID
exports.getItemById = async (req, res) => {
  const { id } = req.params;
  try {
    const item = await pool.query('SELECT * FROM inventory WHERE id = $1', [id]);
    res.json(item.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Update Item
exports.updateItem = async (req, res) => {
  const io = req.app.get('socketio');
  const { id } = req.params;
  const { name, category_id, quantity, location_id } = req.body;
  
  try {
    const updated = await pool.query(
      'UPDATE inventory SET name=$1, category_id=$2, quantity=$3, location_id=$4, updated_at=CURRENT_TIMESTAMP WHERE id=$5 RETURNING *',
      [name, category_id, quantity, location_id, id]
    );

    const updatedItem = updated.rows[0];
    io.emit('inventory-updated'); // Notify all clients

    // Check if stock is low
    if (updatedItem.quantity < 5) {
      io.emit('low-stock-warning', updatedItem);
    }

    res.json(updatedItem);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Delete Item
exports.deleteItem = async (req, res) => {
  const io = req.app.get('socketio');
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM inventory WHERE id=$1', [id]);
    
    io.emit('inventory-updated'); // Emit clearly after deletion
    res.status(204).json({ message: 'Item deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Adjust item quantity (for users and admins)
exports.adjustItemQuantity = async (req, res) => {
    const io = req.app.get('socketio');
    const { itemId, quantityChange } = req.body;

    try {
        // Validate input
        if (!itemId || typeof quantityChange !== 'number' || quantityChange === 0) {
            return res.status(400).json({ error: 'Invalid input data' });
        }

        // Fetch item from database
        const itemQuery = await pool.query('SELECT * FROM inventory WHERE id = $1', [itemId]);
        if (itemQuery.rows.length === 0) {
            return res.status(404).json({ error: 'Item not found' });
        }

        let item = itemQuery.rows[0];

        // Prevent negative quantity
        if (item.quantity + quantityChange < 0) {
            return res.status(400).json({ error: 'Quantity cannot go below zero' });
        }

        // Adjust quantity
        item.quantity += quantityChange;

        // Update database
        const updatedItem = await pool.query(
            'UPDATE inventory SET quantity=$1, updated_at=CURRENT_TIMESTAMP WHERE id=$2 RETURNING *',
            [item.quantity, itemId]
        );

        io.emit('inventory-updated'); // Notify clients

        return res.status(200).json({ 
            message: `Quantity updated successfully. New quantity: ${item.quantity}`, 
            item: updatedItem.rows[0] 
        });

    } catch (error) {
        console.error('❌ Error adjusting quantity:', error);
        res.status(500).json({ error: 'Server error adjusting quantity' });
    }
};
