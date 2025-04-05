const express = require('express');
const router = express.Router();
const { signIn, signUp } = require('../controllers/authController');

// Sign up route
router.post('/signup', signUp);

// Sign in route
router.post('/signin', signIn);

module.exports = router; 