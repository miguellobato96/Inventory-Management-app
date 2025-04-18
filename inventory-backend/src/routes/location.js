const express = require('express');
const router = express.Router();
const { verifyToken, requireAdmin } = require('../middleware/authMiddleware');
const locationController = require('../controllers/locationController');

router.use(verifyToken);

// Get all locations
router.get('/', locationController.getLocations);

// Add a new location (admin only)
router.post('/', requireAdmin, locationController.createLocation);

// Update location (admin only)
router.put('/:id', requireAdmin, locationController.updateLocation);

// Delete location (admin only)
router.delete('/:id', requireAdmin, locationController.deleteLocation);

module.exports = router;
