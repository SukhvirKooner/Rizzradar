const shortid = require('shortid');

// In-memory storage for demo
let groups = [];

const createGroup = async (req, res) => {
    try {
        const { name, description } = req.body;
        const userId = req.user.id; // From auth middleware

        const newGroup = {
            _id: shortid.generate(),
            name,
            description,
            creator: userId,
            members: [userId],
            inviteCode: shortid.generate(),
            createdAt: new Date()
        };

        groups.push(newGroup);

        res.status(201).json({
            success: true,
            data: newGroup
        });
    } catch (error) {
        console.error('Create group error:', error);
        res.status(500).json({
            success: false,
            error: 'Error creating group'
        });
    }
};

const joinGroup = async (req, res) => {
    try {
        const { inviteCode } = req.body;
        const userId = req.user.id;

        const group = groups.find(g => g.inviteCode === inviteCode);
        if (!group) {
            return res.status(404).json({
                success: false,
                error: 'Group not found'
            });
        }

        if (!group.members.includes(userId)) {
            group.members.push(userId);
        }

        res.json({
            success: true,
            data: group
        });
    } catch (error) {
        console.error('Join group error:', error);
        res.status(500).json({
            success: false,
            error: 'Error joining group'
        });
    }
};

const getUserGroups = async (req, res) => {
    try {
        const userId = req.user.id;
        const userGroups = groups.filter(group => group.members.includes(userId));

        res.json({
            success: true,
            data: userGroups
        });
    } catch (error) {
        console.error('Get user groups error:', error);
        res.status(500).json({
            success: false,
            error: 'Error getting user groups'
        });
    }
};

const getGroupMembers = async (req, res) => {
    try {
        const { groupId } = req.params;
        const group = groups.find(g => g._id === groupId);

        if (!group) {
            return res.status(404).json({
                success: false,
                error: 'Group not found'
            });
        }

        // For demo, we'll return dummy user objects for each member ID
        const members = group.members.map(memberId => ({
            _id: memberId,
            username: `User-${memberId}`,
            email: `user-${memberId}@example.com`
        }));

        res.json({
            success: true,
            data: members
        });
    } catch (error) {
        console.error('Get group members error:', error);
        res.status(500).json({
            success: false,
            error: 'Error getting group members'
        });
    }
};

module.exports = {
    createGroup,
    joinGroup,
    getUserGroups,
    getGroupMembers
}; 