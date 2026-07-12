const prisma = require("./config/prisma");
const { ensureDefaultCategories } = require("./config/defaultCategories");

exports.list = async (req, res) => {
  try {
    await ensureDefaultCategories(prisma, req.auth.user_id);
    const categories = await prisma.categories.findMany({
      where: { user_id: req.auth.user_id },
      orderBy: [{ is_default: "desc" }, { category_name: "asc" }],
    });
    res.json(categories);
  } catch (error) {
    console.error("List categories failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.create = async (req, res) => {
  try {
    const { category_name, icon, category_type } = req.body;
    if (typeof category_name !== "string" || !category_name.trim() || category_name.trim().length > 50) {
      return res.status(400).json({ message: "Category name is required and must be 50 characters or fewer" });
    }
    if (icon != null && (typeof icon !== "string" || icon.length > 50)) {
      return res.status(400).json({ message: "Icon must be 50 characters or fewer" });
    }
    if (category_type !== "income" && category_type !== "expense") {
      return res.status(400).json({ message: "category_type is required and must be 'income' or 'expense'" });
    }
    const category = await prisma.categories.create({
      data: {
        user_id: req.auth.user_id,
        category_name: category_name.trim(),
        icon: icon?.trim() || null,
        category_type,
      },
    });
    res.status(201).json(category);
  } catch (error) {
    if (error.code === "P2002") return res.status(400).json({ message: "A category with that name already exists" });
    console.error("Create category failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};
