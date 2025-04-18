const pool = require('../config/db');

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

// Adjust item quantity & update history
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
                location_name: item.location_name // Include location in response
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

// Fetch Dashboard Insights
exports.getDashboardInsights = async (req, res) => {
    try {
        console.log("📊 Fetching Dashboard Insights...");

        // Fetch Top 5 Most Frequently Low-Stock Items
        const lowStockItems = await pool.query(`
            SELECT i.name, COUNT(*) AS low_stock_count
            FROM inventory_history ih
            JOIN inventory i ON ih.item_id = i.id
            WHERE i.quantity <= i.low_stock_threshold
            GROUP BY i.name
            ORDER BY low_stock_count DESC
            LIMIT 5;
        `);

        // Fetch Top 5 Most Used Items (Highest Negative Changes)
        const mostUsedItems = await pool.query(`
            SELECT i.name, ABS(SUM(ih.quantity_change)) AS total_usage
            FROM inventory_history ih
            JOIN inventory i ON ih.item_id = i.id
            WHERE ih.quantity_change < 0
            GROUP BY i.name
            ORDER BY total_usage DESC
            LIMIT 5;
        `);

        res.status(200).json({
            top_low_stock_items: lowStockItems.rows,
            most_used_items: mostUsedItems.rows, // Updated key name
        });

        console.log("✅ Dashboard Insights Sent!");

    } catch (error) {
        console.error("❌ Error fetching dashboard insights:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

// Create a new lift (single record with multiple items)
exports.createLift = async (req, res) => {
  const userId = req.user.id;
  const { unitId, items } = req.body;

  if (!unitId || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ message: "Unit ID and items are required" });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Create a new lift entry
    const liftResult = await client.query(
      'INSERT INTO unit_lifts (user_id, unit_id, status) VALUES ($1, $2, $3) RETURNING id',
      [userId, unitId, 'active']
    );
    const liftId = liftResult.rows[0].id;

    for (const item of items) {
      await client.query(
        'INSERT INTO unit_item_lifts (lift_id, item_id, quantity, status) VALUES ($1, $2, $3, $4)',
        [liftId, item.item_id, item.quantity, 'active']
      );

      await client.query(
        'UPDATE inventory SET quantity = quantity - $1 WHERE id = $2 AND quantity >= $1',
        [item.quantity, item.item_id]
      );
    }

    await client.query('COMMIT');
    return res.status(200).json({ message: "Lift created successfully", liftId });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error("Create lift error:", err);
    return res.status(500).json({ message: "Internal server error" });
  } finally {
    client.release();
  }
};

// Clear lifted items for a specific unit
exports.clearLiftForUnit = async (req, res) => {
  const userId = req.user.id;
  const unitId = req.params.unitId;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const result = await client.query(
      `SELECT id FROM unit_lifts WHERE user_id = $1 AND unit_id = $2 AND status = 'active'`,
      [userId, unitId]
    );

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: "No active lift found to clear." });
    }

    const liftId = result.rows[0].id;

    await client.query(`DELETE FROM unit_item_lifts WHERE lift_id = $1`, [liftId]);
    await client.query(`DELETE FROM unit_lifts WHERE id = $1`, [liftId]);

    await client.query('COMMIT');
    return res.status(200).json({ message: "Lift cleared" });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error("Clear lift error:", err);
    return res.status(500).json({ message: "Internal server error" });
  } finally {
    client.release();
  }
};

// Get lifted items for a specific unit
exports.getLiftsByUnit = async (req, res) => {
  const userId = req.user.id;
  const unitId = req.params.unitId;

  try {
    const result = await pool.query(
      `SELECT ul.id AS lift_id, ul.created_at, COUNT(uil.id) AS total_items
       FROM unit_lifts ul
       LEFT JOIN unit_item_lifts uil ON ul.id = uil.lift_id
       WHERE ul.user_id = $1 AND ul.unit_id = $2
       GROUP BY ul.id
       ORDER BY ul.created_at DESC`,
      [userId, unitId]
    );

    res.status(200).json(result.rows);
  } catch (err) {
    console.error("Get lifts error:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// Return lifted items (mark as returned, separate damaged)
exports.returnLiftedItems = async (req, res) => {
  const liftId = parseInt(req.params.liftId);
  const { damagedItems } = req.body;
  const userId = req.user.id;

  if (!liftId || !Array.isArray(damagedItems)) {
    return res.status(400).json({ message: "Lift ID and damaged items are required" });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const liftItems = await client.query(
      `SELECT uil.item_id, uil.quantity, ul.unit_id
       FROM unit_item_lifts uil
       JOIN unit_lifts ul ON uil.lift_id = ul.id
       WHERE uil.lift_id = $1 AND ul.user_id = $2 AND uil.status = 'active'`,
      [liftId, userId]
    );

    if (liftItems.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: "Lift not found or unauthorized" });
    }

    const lift = liftItems.rows[0];
    const damagedMap = new Map();
    for (const item of damagedItems) {
      damagedMap.set(item.item_id, item.quantity);
    }

    for (const liftItem of liftItems.rows) {
      const itemId = liftItem.item_id;
      const liftedQty = liftItem.quantity;
      const damagedQty = damagedMap.get(itemId) || 0;
      const returnQty = liftedQty - damagedQty;

      if (damagedQty > 0) {
        await client.query(
          `INSERT INTO damaged_items (user_id, unit_id, item_id, quantity) 
           VALUES ($1, $2, $3, $4)`,
          [userId, lift.unit_id, itemId, damagedQty]
        );
      }

      if (returnQty > 0) {
        await client.query(
          `UPDATE inventory SET quantity = quantity + $1 WHERE id = $2`,
          [returnQty, itemId]
        );
      }
    }

    await client.query(
      `UPDATE unit_lifts 
       SET status = 'returned', returned_at = CURRENT_TIMESTAMP 
       WHERE id = $1 AND user_id = $2 AND status = 'active'`,
      [liftId, userId]
    );

    await client.query(
      `UPDATE unit_item_lifts
       SET status = 'returned'
       WHERE lift_id = $1`,
      [liftId]
    );

    await client.query('COMMIT');
    return res.status(200).json({ message: "Lift returned and damaged items recorded." });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error("Return lift error:", err);
    res.status(500).json({ message: "Internal server error" });
  } finally {
    client.release();
  }
};

exports.getLiftItemsByLiftId = async (req, res) => {
  const liftId = req.params.liftId;

  try {
    const result = await pool.query(
      `SELECT l.id, l.item_id, i.name AS item_name, l.quantity
       FROM unit_item_lifts l
       JOIN inventory i ON l.item_id = i.id
       WHERE l.lift_id = $1`,
      [liftId]
    );

    res.status(200).json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching lift items:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

exports.getAllDamagedItems = async (req, res) => {
  const client = await pool.connect();
  try {
    const result = await client.query(`
      SELECT d.id, d.quantity, d.created_at,
             i.name AS item_name,
             u.name AS unit_name,
             us.username AS user_name
      FROM damaged_items d
      JOIN inventory i ON d.item_id = i.id
      JOIN units u ON d.unit_id = u.id
      JOIN users us ON d.user_id = us.id
      ORDER BY d.created_at DESC
    `);

    res.status(200).json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar itens danificados:", err);
    res.status(500).json({ message: "Erro ao buscar itens danificados" });
  } finally {
    client.release();
  }
};
