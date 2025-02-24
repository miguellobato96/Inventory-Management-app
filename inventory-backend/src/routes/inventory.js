const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/authMiddleware');

router.get('/', verifyToken, (req, res) => {
  res.json({ message: 'This inventory route is protected!' });
});

module.exports = router;
