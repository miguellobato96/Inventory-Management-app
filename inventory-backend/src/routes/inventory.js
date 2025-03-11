const express = require('express');
const router = express.Router();
const { verifyToken, requireAdmin } = require('../middleware/authMiddleware');
const inventoryController = require('../controllers/inventoryController');

// All users must be authenticated
router.use(verifyToken);

// Routes for all users
router.get('/', inventoryController.getItems);
router.get('/:id', inventoryController.getItemById);
router.post('/adjust-quantity', inventoryController.adjustItemQuantity);


// Routes only accessible to Admins
router.post('/', requireAdmin, inventoryController.createItem);
router.put('/:id', requireAdmin, inventoryController.updateItem);
router.delete('/:id', requireAdmin, inventoryController.deleteItem);

module.exports = router;
