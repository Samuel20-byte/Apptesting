const prisma = require("./config/prisma");

exports.list = async (req, res) => {
  try {
    const goals = await prisma.financial_goals.findMany({
      where: { user_id: req.auth.user_id },
      orderBy: { goal_id: "asc" },
    });
    res.json(goals);
  } catch (error) {
    console.error("List goals failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};
