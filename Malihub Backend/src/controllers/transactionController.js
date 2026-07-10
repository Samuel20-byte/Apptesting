const prisma = require("./config/prisma");

const parsePositiveInteger = (value, fallback, max) => {
  const number = Number.parseInt(value, 10);
  return Number.isInteger(number) && number > 0 ? Math.min(number, max) : fallback;
};

const monthBounds = (year, month) => {
  const start = new Date(year, month - 1, 1);
  const end = new Date(year, month, 1);
  return { start, end };
};

exports.list = async (req, res) => {
  try {
    const limit = parsePositiveInteger(req.query.limit, 50, 100);
    const offset = Number.parseInt(req.query.offset, 10) || 0;
    const transactions = await prisma.transactions.findMany({
      where: { accounts: { user_id: req.auth.user_id } },
      include: {
        accounts: { select: { account_name: true } },
        categories: { select: { category_name: true } },
      },
      orderBy: [{ transaction_date: "desc" }, { transaction_id: "desc" }],
      take: limit,
      skip: Math.max(offset, 0),
    });
    res.json(transactions);
  } catch (error) {
    console.error("List transactions failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.summary = async (req, res) => {
  try {
    const now = new Date();
    const month = parsePositiveInteger(req.query.month, now.getMonth() + 1, 12);
    const year = parsePositiveInteger(req.query.year, now.getFullYear(), 9999);
    if (month > 12 || year < 2000) {
      return res.status(400).json({ message: "Provide a valid month and year" });
    }

    const { start, end } = monthBounds(year, month);
    const previous = monthBounds(month === 1 ? year - 1 : year, month === 1 ? 12 : month - 1);
    const transactions = await prisma.transactions.findMany({
      where: {
        accounts: { user_id: req.auth.user_id },
        transaction_date: { gte: previous.start, lt: end },
      },
      include: { categories: { select: { category_name: true } } },
    });

    let totalIncome = 0;
    let totalExpense = 0;
    let previousMonthExpense = 0;
    const byCategory = {};
    for (const transaction of transactions) {
      const amount = Number(transaction.amount);
      const date = new Date(transaction.transaction_date);
      if (date >= start) {
        if (transaction.transaction_type === "credit") totalIncome += amount;
        else {
          totalExpense += amount;
          const name = transaction.categories.category_name;
          byCategory[name] = (byCategory[name] || 0) + amount;
        }
      } else if (transaction.transaction_type === "debit") {
        previousMonthExpense += amount;
      }
    }

    res.json({
      month,
      year,
      total_income: totalIncome,
      total_expense: totalExpense,
      net: totalIncome - totalExpense,
      by_category: byCategory,
      previous_month_expense: previousMonthExpense,
    });
  } catch (error) {
    console.error("Transaction summary failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};
