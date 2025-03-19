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
                inventory.low_stock_threshold, 
                CASE 
                    WHEN inventory.quantity <= inventory.low_stock_threshold THEN true 
                    ELSE false 
                END AS is_low_stock, 
                inventory.location_id, 
                COALESCE(locations.name, 'Não Atribuído') AS location_name
            FROM inventory
            LEFT JOIN locations ON inventory.location_id = locations.id
            LEFT JOIN categories ON inventory.category_id = categories.id
            WHERE inventory.category_id IN (SELECT id FROM category_tree) 
               OR inventory.category_id IS NULL
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

// Adjust item quantity (for users and admins) & Log History
exports.adjustItemQuantity = async (req, res) => {
    const io = req.app.get('socketio');
    const { itemId, quantityChange } = req.body;
    const userId = req.user.id; // Get user ID from auth middleware

    try {
        // Validate input
        if (!itemId || typeof quantityChange !== 'number' || quantityChange === 0) {
            return res.status(400).json({ error: 'Invalid input data' });
        }

        // Fetch item with location
        const itemQuery = await pool.query(`
            SELECT inventory.*, COALESCE(locations.name, 'Unknown Location') AS location_name
            FROM inventory
            LEFT JOIN locations ON inventory.location_id = locations.id
            WHERE inventory.id = $1
        `, [itemId]);

        if (itemQuery.rows.length === 0) {
            return res.status(404).json({ error: 'Item not found' });
        }

        let item = itemQuery.rows[0];

        // Prevent negative quantity
        if (item.quantity + quantityChange < 0) {
            return res.status(400).json({ error: 'Quantity cannot go below zero' });
        }

        // Store previous & new quantity
        const previousQuantity = item.quantity;
        const newQuantity = previousQuantity + quantityChange;

        // Update database
        const updatedItem = await pool.query(
            'UPDATE inventory SET quantity=$1, updated_at=CURRENT_TIMESTAMP WHERE id=$2 RETURNING *',
            [newQuantity, itemId]
        );

        // Insert changes into history
        await pool.query(`
            INSERT INTO inventory_history (item_id, user_id, quantity_before, quantity_change, quantity_after)
            VALUES ($1, $2, $3, $4, $5)
        `, [itemId, userId, previousQuantity, quantityChange, newQuantity]);

        // Notify clients
        io.emit('inventory-updated');

        return res.status(200).json({ 
            message: `Quantity updated successfully. New quantity: ${newQuantity}`,
            item: {
                ...updatedItem.rows[0],
                location_name: item.location_name // ✅ Include location in response
            }
        });

    } catch (error) {
        console.error('❌ Error adjusting quantity:', error);
        res.status(500).json({ error: 'Server error adjusting quantity' });
    }
};

// Fetch inventory change history
exports.getInventoryHistory = async (req, res) => {
    try {
        const history = await pool.query(`
            SELECT ih.id, 
                   ih.item_id, 
                   i.name AS item_name, 
                   u.username,
                   ih.quantity_before, 
                   ih.quantity_change, 
                   ih.quantity_after, 
                   TO_CHAR(ih.changed_at, 'DD/MM/YYYY HH24:MI') AS changed_at
            FROM inventory_history ih
            JOIN inventory i ON ih.item_id = i.id
            JOIN users u ON ih.user_id = u.id
            ORDER BY ih.changed_at DESC;
        `);

        res.status(200).json(history.rows);
    } catch (error) {
        console.error('❌ Error fetching inventory history:', error);
        res.status(500).json({ error: 'Server error fetching history' });
    }
};

const exportService = require("../services/exportService");
const emailService = require("../services/emailService");

// Export Inventory
exports.exportInventory = async (req, res) => {
    const { format, email, category_id, sort_by, order, low_stock_only } = req.body;

    try {
        console.log("📥 Received Export Request:", req.body);

        if (!email || !format || !["csv", "pdf", "both"].includes(format)) {
            return res.status(400).json({ error: "Invalid input. Please specify email and format (csv, pdf, both)." });
        }

        let query = `
            SELECT inventory.id, inventory.name, 
                   CASE 
                       WHEN categories.parent_id IS NULL THEN categories.name 
                       ELSE parent_categories.name 
                   END AS category,
                   CASE 
                       WHEN categories.parent_id IS NOT NULL THEN categories.name 
                       ELSE 'No Subcategory' 
                   END AS subcategory,
                   inventory.quantity, 
                   inventory.low_stock_threshold,
                   CASE 
                       WHEN inventory.quantity <= inventory.low_stock_threshold THEN true 
                       ELSE false 
                   END AS is_low_stock,
                   COALESCE(locations.name, 'Unknown') AS location_name
            FROM inventory
            LEFT JOIN categories ON inventory.category_id = categories.id
            LEFT JOIN categories parent_categories ON categories.parent_id = parent_categories.id
            LEFT JOIN locations ON inventory.location_id = locations.id
        `;

        let params = [];
        let conditions = [];

        // Filter by category
        if (category_id) {
            params.push(category_id);
            conditions.push(`inventory.category_id = $${params.length}`);
        }

        // Filter by low-stock only
        if (low_stock_only) {
            conditions.push(`inventory.quantity <= inventory.low_stock_threshold`);
        }

        // Apply WHERE conditions if needed
        if (conditions.length > 0) {
            query += ` WHERE ` + conditions.join(" AND ");
        }

        // Sorting
        if (sort_by) {
            query += ` ORDER BY ${sort_by} ${order === "desc" ? "DESC" : "ASC"}`;
        }

        console.log("📤 Running SQL Query:\n", query, params);

        const result = await pool.query(query, params);
        console.log("✅ Query Result:", result.rows.length, "records found");

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "No inventory records found." });
        }

        // Generate CSV/PDF and send email
        let attachments = [];
        if (format === "csv" || format === "both") {
            const csvPath = await exportService.generateCSV(result.rows);
            attachments.push(csvPath);
        }
        if (format === "pdf" || format === "both") {
            const pdfPath = await exportService.generatePDF(result.rows);
            attachments.push(pdfPath);
        }

        await emailService.sendEmailWithAttachments(email, attachments);

        console.log("📧 Export Successful. Email sent to:", email);
        res.status(200).json({ message: "Export successful. Check your email for the files." });

    } catch (err) {
        console.error("❌ Error exporting inventory:", err);
        res.status(500).json({ error: err.message });
    }
};
