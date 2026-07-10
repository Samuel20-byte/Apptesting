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

const validTransactionType = (value) => value === "credit" || value === "debit";
const validDate = (value) => {
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? null : date;
};
const transactionInclude = {
  accounts: { select: { account_name: true } },
  categories: { select: { category_name: true } },
};

async function hasOwnedAccount(accountId, userId) {
  return prisma.accounts.findFirst({ where: { account_id: Number(accountId), user_id: userId, is_active: true } });
}

async function hasOwnedCategory(categoryId, userId) {
  return prisma.categories.findFirst({ where: { category_id: Number(categoryId), user_id: userId } });
}

async function ownedTransaction(transactionId, userId) {
  const id = Number.parseInt(transactionId, 10);
  if (!Number.isInteger(id)) return null;
  return prisma.transactions.findFirst({
    where: { transaction_id: id, accounts: { user_id: userId } },
    include: transactionInclude,
  });
}

exports.list = async (req, res) => {
  try {
    const limit = parsePositiveInteger(req.query.limit, 50, 100);
    const offset = Number.parseInt(req.query.offset, 10) || 0;
    const transactions = await prisma.transactions.findMany({
      where: { accounts: { user_id: req.auth.user_id } },
      include: transactionInclude,
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

exports.create = async (req, res) => {
  try {
    const { account_id, category_id, amount, transaction_type, description, transaction_date } = req.body;
    const parsedAmount = Number(amount);
    const date = transaction_date == null ? new Date() : validDate(transaction_date);
    if (!Number.isInteger(Number(account_id)) || !Number.isInteger(Number(category_id)) || !Number.isFinite(parsedAmount) || parsedAmount <= 0 || !validTransactionType(transaction_type) || !date) {
      return res.status(400).json({ message: "Provide a valid account, category, positive amount, type, and date" });
    }
    if (description != null && (typeof description !== "string" || description.length > 150)) {
      return res.status(400).json({ message: "Description must be 150 characters or fewer" });
    }
    if (!(await hasOwnedAccount(account_id, req.auth.user_id)) || !(await hasOwnedCategory(category_id, req.auth.user_id))) {
      return res.status(400).json({ message: "Choose an account and category from your profile" });
    }
    const transaction = await prisma.transactions.create({
      data: {
        account_id: Number(account_id),
        category_id: Number(category_id),
        amount: parsedAmount,
        transaction_type,
        description: description?.trim() || null,
        transaction_date: date,
      },
      include: transactionInclude,
    });
    res.status(201).json(transaction);
  } catch (error) {
    console.error("Create transaction failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.update = async (req, res) => {
  try {
    const transaction = await ownedTransaction(req.params.transactionId, req.auth.user_id);
    if (!transaction) return res.status(404).json({ message: "Transaction not found" });
    const { category_id, amount, transaction_type, description, transaction_date } = req.body;
    const data = {};
    if (category_id !== undefined) {
      if (!Number.isInteger(Number(category_id)) || !(await hasOwnedCategory(category_id, req.auth.user_id))) {
        return res.status(400).json({ message: "Choose a category from your profile" });
      }
      data.category_id = Number(category_id);
    }
    if (amount !== undefined) {
      const parsedAmount = Number(amount);
      if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) return res.status(400).json({ message: "Amount must be positive" });
      data.amount = parsedAmount;
    }
    if (transaction_type !== undefined) {
      if (!validTransactionType(transaction_type)) return res.status(400).json({ message: "Transaction type must be credit or debit" });
      data.transaction_type = transaction_type;
    }
    if (description !== undefined) {
      if (description !== null && (typeof description !== "string" || description.length > 150)) return res.status(400).json({ message: "Description must be 150 characters or fewer" });
      data.description = description?.trim() || null;
    }
    if (transaction_date !== undefined) {
      const date = validDate(transaction_date);
      if (!date) return res.status(400).json({ message: "Transaction date is invalid" });
      data.transaction_date = date;
    }
    if (!Object.keys(data).length) return res.status(400).json({ message: "No transaction changes were provided" });
    res.json(await prisma.transactions.update({
      where: { transaction_id: transaction.transaction_id },
      data,
      include: transactionInclude,
    }));
  } catch (error) {
    console.error("Update transaction failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.remove = async (req, res) => {
  try {
    const transaction = await ownedTransaction(req.params.transactionId, req.auth.user_id);
    if (!transaction) return res.status(404).json({ message: "Transaction not found" });
    await prisma.transactions.delete({ where: { transaction_id: transaction.transaction_id } });
    res.status(204).end();
  } catch (error) {
    console.error("Delete transaction failed:", error.message);
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
