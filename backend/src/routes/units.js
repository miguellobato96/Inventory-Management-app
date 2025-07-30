// routes/unitRoutes.js
const express = require('express');
const router = express.Router();
const unitController = require('../controllers/unitController');
const { verifyToken, requireAdmin } = require('../middleware/authMiddleware');

router.use(verifyToken);

router.get('/user', unitController.getUserUnits);
router.post('/', unitController.createUnit);
router.put('/:id', unitController.updateUnit);
router.delete('/:id', unitController.deleteUnit);
router.get('/:id/history', unitController.getUserUnitLifts);

module.exports = router;