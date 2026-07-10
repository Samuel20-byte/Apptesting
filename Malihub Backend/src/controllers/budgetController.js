const prisma = require("./config/prisma");

const periodTypes = new Set(["weekly", "monthly", "yearly"]);
const decimal = (value) => Number.isFinite(Number(value)) ? Number(value) : null;

const parseDate = (value) => {
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? null : date;
};

function periodEnd(startDate, periodType) {
  const end = new Date(startDate);
  if (periodType === "weekly") end.setDate(end.getDate() + 7);
  if (periodType === "monthly") end.setMonth(end.getMonth() + 1);
  if (periodType === "yearly") end.setFullYear(end.getFullYear() + 1);
  return end;
}

async function ownedBudget(id, userId) {
  const budgetId = Number.parseInt(id, 10);
  if (!Number.isInteger(budgetId)) return null;
  return prisma.budgets.findFirst({
    where: { budget_id: budgetId, user_id: userId },
    include: { categories: { select: { category_name: true } } },
  });
}

async function ownedCategory(id, userId) {
  return prisma.categories.findFirst({
    where: { category_id: Number(id), user_id: userId },
  });
}

async function withProgress(budget, userId) {
  const start = new Date(budget.start_date);
  const end = periodEnd(start, budget.period_type);
  const result = await prisma.transactions.aggregate({
    _sum: { amount: true },
    where: {
      category_id: budget.category_id,
      transaction_type: "debit",
      transaction_date: { gte: start, lt: end },
      accounts: { user_id: userId },
    },
  });
  const budgetAmount = Number(budget.budget_amount);
  const spent = Number(result._sum.amount || 0);
  return {
    ...budget,
    spent,
    remaining: budgetAmount - spent,
    percent_used: budgetAmount > 0 ? Math.round((spent / budgetAmount) * 100) : 0,
  };
}

exports.list = async (req, res) => {
  try {
    const budgets = await prisma.budgets.findMany({
      where: { user_id: req.auth.user_id },
      include: { categories: { select: { category_name: true } } },
      orderBy: { budget_id: "asc" },
    });
    res.json(await Promise.all(budgets.map((budget) => withProgress(budget, req.auth.user_id))));
  } catch (error) {
    console.error("List budgets failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.create = async (req, res) => {
  try {
    const { category_id, budget_amount, period_type, start_date, alert_threshold } = req.body;
    const amount = decimal(budget_amount);
    const threshold = alert_threshold == null ? null : decimal(alert_threshold);
    const start = parseDate(start_date);
    if (!Number.isInteger(Number(category_id)) || amount == null || amount <= 0 || !periodTypes.has(period_type) || !start || (threshold != null && (threshold < 0 || threshold > 100))) {
      return res.status(400).json({ message: "Provide a category, positive budget amount, valid period and start date" });
    }
    if (!(await ownedCategory(category_id, req.auth.user_id))) {
      return res.status(400).json({ message: "Choose a category from your profile" });
    }
    const existing = await prisma.budgets.findFirst({
      where: { user_id: req.auth.user_id, category_id: Number(category_id), period_type, start_date: start },
    });
    if (existing) return res.status(400).json({ message: "A budget already exists for this category and period" });
    const budget = await prisma.budgets.create({
      data: {
        user_id: req.auth.user_id,
        category_id: Number(category_id),
        budget_amount: amount,
        period_type,
        start_date: start,
        alert_threshold: threshold,
      },
      include: { categories: { select: { category_name: true } } },
    });
    res.status(201).json(await withProgress(budget, req.auth.user_id));
  } catch (error) {
    console.error("Create budget failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.update = async (req, res) => {
  try {
    const budget = await ownedBudget(req.params.budgetId, req.auth.user_id);
    if (!budget) return res.status(404).json({ message: "Budget not found" });
    const { budget_amount, period_type, start_date, alert_threshold } = req.body;
    const data = {};
    if (budget_amount !== undefined) {
      const amount = decimal(budget_amount);
      if (amount == null || amount <= 0) return res.status(400).json({ message: "Budget amount must be positive" });
      data.budget_amount = amount;
    }
    if (period_type !== undefined) {
      if (!periodTypes.has(period_type)) return res.status(400).json({ message: "Budget period is invalid" });
      data.period_type = period_type;
    }
    if (start_date !== undefined) {
      const start = parseDate(start_date);
      if (!start) return res.status(400).json({ message: "Start date is invalid" });
      data.start_date = start;
    }
    if (alert_threshold !== undefined) {
      const threshold = alert_threshold == null ? null : decimal(alert_threshold);
      if (threshold != null && (threshold < 0 || threshold > 100)) return res.status(400).json({ message: "Alert threshold must be between 0 and 100" });
      data.alert_threshold = threshold;
    }
    if (!Object.keys(data).length) return res.status(400).json({ message: "No budget changes were provided" });
    const updated = await prisma.budgets.update({
      where: { budget_id: budget.budget_id },
      data,
      include: { categories: { select: { category_name: true } } },
    });
    res.json(await withProgress(updated, req.auth.user_id));
  } catch (error) {
    console.error("Update budget failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.remove = async (req, res) => {
  try {
    const budget = await ownedBudget(req.params.budgetId, req.auth.user_id);
    if (!budget) return res.status(404).json({ message: "Budget not found" });
    await prisma.budgets.delete({ where: { budget_id: budget.budget_id } });
    res.status(204).end();
  } catch (error) {
    console.error("Delete budget failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};
