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

router.post('/lift', verifyToken, inventoryController.createLift);
router.delete('/lift/:unitId', verifyToken, inventoryController.clearLiftForUnit);
router.get('/lifts/:unitId', verifyToken, inventoryController.getLiftsByUnit);
router.post('/lifts/:liftId/return', verifyToken, inventoryController.returnLiftedItems);
router.get('/lifts/:liftId/items', verifyToken, inventoryController.getLiftItemsByLiftId);


// Routes only accessible to Admins
router.get('/damaged-items', requireAdmin, inventoryController.getAllDamagedItems);
router.get('/dashboard', requireAdmin, inventoryController.getDashboardInsights);
router.post('/export', requireAdmin, inventoryController.exportInventory);
router.get('/history', requireAdmin, inventoryController.getInventoryHistory);

module.exports = router;