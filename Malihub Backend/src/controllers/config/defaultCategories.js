const defaultCategories = [
  { category_name: "Salary", icon: "payments", category_type: "income" },
  { category_name: "Freelance", icon: "work", category_type: "income" },
  { category_name: "Groceries", icon: "shopping_cart", category_type: "expense" },
  { category_name: "Transport", icon: "directions_car", category_type: "expense" },
  { category_name: "Rent & Bills", icon: "home", category_type: "expense" },
  { category_name: "Savings", icon: "savings", category_type: "expense" },
  { category_name: "Entertainment", icon: "movie", category_type: "expense" },
];

async function ensureDefaultCategories(prisma, userId) {
  const count = await prisma.categories.count({ where: { user_id: userId } });
  if (count > 0) return;
  await prisma.categories.createMany({
    data: defaultCategories.map((category) => ({ ...category, user_id: userId, is_default: true })),
    skipDuplicates: true,
  });
}

module.exports = { ensureDefaultCategories };
