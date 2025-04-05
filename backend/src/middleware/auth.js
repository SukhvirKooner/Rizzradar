const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
    try {
        // Get token from header
        const token = req.header('Authorization')?.replace('Bearer ', '');
        
        if (!token) {
            return res.status(401).json({
                success: false,
                error: 'No token, authorization denied'
            });
        }

        // For demo: accept any token and set a demo user
        req.user = {
            id: 'demo-user-id',
            email: 'demo@example.com',
            username: 'demo-user'
        };
        
        next();
    } catch (error) {
        res.status(401).json({
            success: false,
            error: 'Token is not valid'
        });
    }
}; 