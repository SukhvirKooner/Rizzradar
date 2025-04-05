const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

const signIn = async (req, res) => {
    try {
        const { email, password } = req.body;
        
        // Demo: Generate token for any email/password combination
        const token = jwt.sign(
            { 
                id: 'demo-user-id',
                email: email,
                username: email.split('@')[0] // Use part before @ as username
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            success: true,
            data: {
                token,
                user: {
                    id: 'demo-user-id',
                    email: email,
                    username: email.split('@')[0]
                }
            }
        });
    } catch (error) {
        console.error('Sign in error:', error);
        res.status(500).json({
            success: false,
            error: 'Error signing in'
        });
    }
};

const signUp = async (req, res) => {
    try {
        const { email, password, username } = req.body;
        
        // Demo: Generate token for any registration
        const token = jwt.sign(
            { 
                id: 'demo-user-id',
                email,
                username: username || email.split('@')[0]
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.status(201).json({
            success: true,
            data: {
                token,
                user: {
                    id: 'demo-user-id',
                    email,
                    username: username || email.split('@')[0]
                }
            }
        });
    } catch (error) {
        console.error('Sign up error:', error);
        res.status(500).json({
            success: false,
            error: 'Error signing up'
        });
    }
};

module.exports = {
    signIn,
    signUp
}; 