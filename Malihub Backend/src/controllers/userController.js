const prisma = require("./config/prisma");
const bcrypt = require("bcrypt");

const publicUser = ({ password_hash, ...user }) => user;

exports.getMe = async (req, res) => {
  try {
    const user = await prisma.users.findUnique({ where: { user_id: req.auth.user_id } });
    if (!user || !user.is_active) return res.status(404).json({ message: "User not found" });
    res.json(publicUser(user));
  } catch (error) {
    console.error("Get user failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.updateMe = async (req, res) => {
  try {
    const { first_name, last_name, phone_number, currency_preference } = req.body;
    const data = {};
    if (first_name !== undefined) {
      if (typeof first_name !== "string" || !first_name.trim() || first_name.trim().length > 50) {
        return res.status(400).json({ message: "First name is required and must be 50 characters or fewer" });
      }
      data.first_name = first_name.trim();
    }
    if (last_name !== undefined) {
      if (typeof last_name !== "string" || !last_name.trim() || last_name.trim().length > 50) {
        return res.status(400).json({ message: "Last name is required and must be 50 characters or fewer" });
      }
      data.last_name = last_name.trim();
    }
    if (phone_number !== undefined) {
      if (phone_number !== null && (typeof phone_number !== "string" || phone_number.trim().length > 20)) {
        return res.status(400).json({ message: "Phone number must be 20 characters or fewer" });
      }
      data.phone_number = phone_number?.trim() || null;
    }
    if (currency_preference !== undefined) {
      if (typeof currency_preference !== "string" || !/^[A-Za-z]{3}$/.test(currency_preference)) {
        return res.status(400).json({ message: "Currency preference must be a three-letter code" });
      }
      data.currency_preference = currency_preference.toUpperCase();
    }
    if (Object.keys(data).length === 0) return res.status(400).json({ message: "No profile changes were provided" });

    const user = await prisma.users.update({
      where: { user_id: req.auth.user_id },
      data,
    });
    res.json(publicUser(user));
  } catch (error) {
    console.error("Update user failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.changePassword = async (req, res) => {
  try {
    const { current_password, new_password } = req.body;
    if (typeof current_password !== "string" || typeof new_password !== "string" || new_password.length < 8) {
      return res.status(400).json({ message: "Current password and a new password of at least 8 characters are required" });
    }
    const user = await prisma.users.findUnique({ where: { user_id: req.auth.user_id } });
    if (!user || !(await bcrypt.compare(current_password, user.password_hash))) {
      return res.status(401).json({ message: "Current password is incorrect" });
    }
    await prisma.users.update({
      where: { user_id: req.auth.user_id },
      data: { password_hash: await bcrypt.hash(new_password, 10) },
    });
    res.status(204).end();
  } catch (error) {
    console.error("Change password failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};
