const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { verifyToken } = require('../middleware/authMiddleware');

router.post('/login', authController.login);
router.get('/user', verifyToken, authController.getUserEmail);
router.get('/users', verifyToken, authController.getAllUsers);
router.get('/email', verifyToken, authController.getUserEmail);


module.exports = router;
