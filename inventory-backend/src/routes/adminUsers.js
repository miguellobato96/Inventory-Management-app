const express = require('express');
const router = express.Router();
const adminUsersController = require('../controllers/adminUsersController');
const { verifyToken, requireAdmin } = require('../middleware/authMiddleware');

// Middleware to verify token and check if user is admin
router.use(verifyToken, requireAdmin);

// GET all users
router.get('/', adminUsersController.getAllUsers);

// GET user history by ID
router.get('/:id/history', adminUsersController.getUserHistory);

// POST create new user
router.post('/', adminUsersController.createUser);

// PUT update user
router.put('/:id', adminUsersController.updateUser);

// DELETE user
router.delete('/:id', adminUsersController.deleteUser);

module.exports = router;