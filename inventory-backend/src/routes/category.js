const express = require('express');
const router = express.Router();
const { verifyToken, requireAdmin } = require('../middleware/authMiddleware');
const categoryController = require('../controllers/categoryController');

// All users must be authenticated
router.use(verifyToken);

// Get only main categories
router.get('/main', categoryController.getMainCategories);

// Get subcategories of a specific category
router.get('/:id/subcategories', categoryController.getSubcategories);

// Add a new category (admin only)
router.post('/', requireAdmin, categoryController.createCategory);

// Update a category (admin only)
router.put('/:id', requireAdmin, categoryController.updateCategory);

// Delete a category (admin only)
router.delete('/:id', requireAdmin, categoryController.deleteCategory);

module.exports = router;
