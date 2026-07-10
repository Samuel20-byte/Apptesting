const prisma = require("./config/prisma");

exports.getMe = async (req, res) => {
  try {
    const user = await prisma.users.findUnique({ where: { user_id: req.auth.user_id } });
    if (!user || !user.is_active) return res.status(404).json({ message: "User not found" });
    const { password_hash, ...publicUser } = user;
    res.json(publicUser);
  } catch (error) {
    console.error("Get user failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};
