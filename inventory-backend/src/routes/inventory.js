const express = require('express');
const router = express.Router();
const { verifyToken, requireAdmin } = require('../middleware/authMiddleware');
const inventoryController = require('../controllers/inventoryController');

// All users must be authenticated
router.use(verifyToken);

// Routes for all users
router.get('/', inventoryController.getItems);
router.get('/:id([0-9]+)', inventoryController.getItemById);
router.post('/adjust-quantity', inventoryController.adjustItemQuantity);

// Routes only accessible to Admins
router.get('/dashboard', verifyToken, inventoryController.getDashboardInsights);
router.post('/export', requireAdmin, inventoryController.exportInventory);
router.get('/history', requireAdmin, inventoryController.getInventoryHistory);
module.exports = router;