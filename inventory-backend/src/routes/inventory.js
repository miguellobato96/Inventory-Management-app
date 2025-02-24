const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/authMiddleware');
const inventoryController = require('../controllers/inventoryController');

// Protected Routes
router.use(verifyToken);

router.post('/', inventoryController.createItem);
router.get('/', inventoryController.getItems);
router.get('/:id', inventoryController.getItemById);
router.put('/:id', inventoryController.updateItem);
router.delete('/:id', inventoryController.deleteItem);

module.exports = router;
