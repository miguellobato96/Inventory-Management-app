const express = require('express');
const router = express.Router();
const { verifyToken, requireAdmin } = require('../middleware/authMiddleware');
const adminInventoryController = require('../controllers/adminInventoryController');

// All admin routes must be authenticated and have admin role
router.use(verifyToken, requireAdmin);

// Routes for admins
router.post('/items', adminInventoryController.createItem);
router.put('/items/:id', adminInventoryController.updateItem);
router.delete('/items/:id', adminInventoryController.deleteItem);

module.exports = router;