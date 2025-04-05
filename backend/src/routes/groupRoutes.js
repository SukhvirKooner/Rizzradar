const express = require('express');
const router = express.Router();
const groupController = require('../controllers/groupController');
const auth = require('../middleware/auth');

// All routes require authentication
router.use(auth);

// Create a new group
router.post('/', groupController.createGroup);

// Join a group using invite code
router.post('/join', groupController.joinGroup);

// Get group members
router.get('/:groupId/members', groupController.getGroupMembers);

// Get user's groups
router.get('/my-groups', groupController.getUserGroups);

module.exports = router; 