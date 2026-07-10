const prisma = require("./config/prisma");

const decimal = (value) => Number.isFinite(Number(value)) ? Number(value) : null;
const dateOrNull = (value) => {
  if (value == null || value === "") return null;
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? undefined : date;
};

async function ownedGoal(goalId, userId) {
  const id = Number.parseInt(goalId, 10);
  if (!Number.isInteger(id)) return null;
  return prisma.financial_goals.findFirst({ where: { goal_id: id, user_id: userId } });
}

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

exports.create = async (req, res) => {
  try {
    const { goal_name, target_amount, current_amount = 0, deadline } = req.body;
    const target = decimal(target_amount);
    const current = decimal(current_amount);
    const parsedDeadline = dateOrNull(deadline);
    if (typeof goal_name !== "string" || !goal_name.trim() || goal_name.trim().length > 50 || target == null || target <= 0 || current == null || current < 0 || parsedDeadline === undefined) {
      return res.status(400).json({ message: "Provide a goal name, positive target, non-negative current amount, and valid deadline" });
    }
    const goal = await prisma.financial_goals.create({
      data: { user_id: req.auth.user_id, goal_name: goal_name.trim(), target_amount: target, current_amount: current, deadline: parsedDeadline },
    });
    res.status(201).json(goal);
  } catch (error) {
    console.error("Create goal failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.update = async (req, res) => {
  try {
    const goal = await ownedGoal(req.params.goalId, req.auth.user_id);
    if (!goal) return res.status(404).json({ message: "Goal not found" });
    const { goal_name, target_amount, deadline } = req.body;
    const data = {};
    if (goal_name !== undefined) {
      if (typeof goal_name !== "string" || !goal_name.trim() || goal_name.trim().length > 50) return res.status(400).json({ message: "Goal name must be 50 characters or fewer" });
      data.goal_name = goal_name.trim();
    }
    if (target_amount !== undefined) {
      const target = decimal(target_amount);
      if (target == null || target <= 0) return res.status(400).json({ message: "Target amount must be positive" });
      data.target_amount = target;
    }
    if (deadline !== undefined) {
      const parsed = dateOrNull(deadline);
      if (parsed === undefined) return res.status(400).json({ message: "Deadline is invalid" });
      data.deadline = parsed;
    }
    if (!Object.keys(data).length) return res.status(400).json({ message: "No goal changes were provided" });
    res.json(await prisma.financial_goals.update({ where: { goal_id: goal.goal_id }, data }));
  } catch (error) {
    console.error("Update goal failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.contribute = async (req, res) => {
  try {
    const goal = await ownedGoal(req.params.goalId, req.auth.user_id);
    const amount = decimal(req.body.amount);
    if (!goal) return res.status(404).json({ message: "Goal not found" });
    if (amount == null || amount <= 0) return res.status(400).json({ message: "Contribution amount must be positive" });
    const updated = await prisma.financial_goals.update({
      where: { goal_id: goal.goal_id },
      data: { current_amount: { increment: amount } },
    });
    res.json(updated);
  } catch (error) {
    console.error("Contribute to goal failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.remove = async (req, res) => {
  try {
    const goal = await ownedGoal(req.params.goalId, req.auth.user_id);
    if (!goal) return res.status(404).json({ message: "Goal not found" });
    await prisma.financial_goals.delete({ where: { goal_id: goal.goal_id } });
    res.status(204).end();
  } catch (error) {
    console.error("Delete goal failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};
