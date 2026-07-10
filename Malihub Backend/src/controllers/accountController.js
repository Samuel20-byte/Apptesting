const prisma = require("./config/prisma");
const accountTypes = new Set(["checking", "savings", "credit_card", "cash"]);

exports.list = async (req, res) => {
  try {
    const accounts = await prisma.accounts.findMany({
      where: { user_id: req.auth.user_id, is_active: true },
      orderBy: { account_id: "asc" },
    });
    res.json(accounts);
  } catch (error) {
    console.error("List accounts failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.create = async (req, res) => {
  try {
    const { account_name, account_type, balance = 0 } = req.body;
    if (typeof account_name !== "string" || !account_name.trim() || account_name.length > 50) {
      return res.status(400).json({ message: "Account name is required and must be 50 characters or fewer" });
    }
    if (!accountTypes.has(account_type) || !Number.isFinite(Number(balance))) {
      return res.status(400).json({ message: "Provide a valid account type and balance" });
    }
    const account = await prisma.accounts.create({
      data: {
        user_id: req.auth.user_id,
        account_name: account_name.trim(),
        account_type,
        balance: Number(balance),
      },
    });
    res.status(201).json(account);
  } catch (error) {
    console.error("Create account failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};
