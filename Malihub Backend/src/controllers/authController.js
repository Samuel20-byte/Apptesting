const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const prisma = require("./config/prisma");
const { ensureDefaultCategories } = require("./config/defaultCategories");
const { sendResetCodeEmail } = require("./config/mailer");

const publicUser = ({ password_hash, ...user }) => user;
const validEmail = (email) =>
  typeof email === "string" && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

const createToken = (user) => {
  if (!process.env.JWT_SECRET) throw new Error("JWT_SECRET is not configured");
  return jwt.sign({ user_id: user.user_id, email: user.email }, process.env.JWT_SECRET, {
    expiresIn: "7d",
  });
};

exports.register = async (req, res) => {
  try {
    const {
      first_name,
      last_name,
      email,
      phone_number,
      password
    } = req.body;

    if (
      typeof first_name !== "string" || !first_name.trim() || first_name.length > 50 ||
      typeof last_name !== "string" || !last_name.trim() || last_name.length > 50 ||
      !validEmail(email) || email.length > 100 ||
      typeof password !== "string" || password.length < 8 ||
      (phone_number != null && (typeof phone_number !== "string" || phone_number.length > 20))
    ) {
      return res.status(400).json({
        message: "Provide valid names, email, an optional phone number, and a password of at least 8 characters",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const existingUser = await prisma.users.findUnique({
      where: { email: normalizedEmail }
    });

    if (existingUser) {
      return res.status(400).json({
        message: "Email already exists"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await prisma.$transaction(async (tx) => {
      const createdUser = await tx.users.create({
        data: {
          first_name: first_name.trim(),
          last_name: last_name.trim(),
          email: normalizedEmail,
          phone_number: phone_number?.trim() || null,
          password_hash: hashedPassword,
        },
      });
      await tx.accounts.create({
        data: {
          user_id: createdUser.user_id,
          account_name: "Main Account",
          account_type: "cash",
          balance: 0,
        },
      });
      await ensureDefaultCategories(tx, createdUser.user_id);
      return createdUser;
    });

    res.status(201).json({
      message: "User registered successfully",
      token: createToken(user),
      user: publicUser(user),
    });

  } catch (error) {
    if (error.code === "P2002") {
      return res.status(400).json({ message: "Email already exists" });
    }
    console.error("Registration failed:", error.message);
    res.status(500).json({
      message: "Server error"
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!validEmail(email) || typeof password !== "string" || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }
    const user = await prisma.users.findUnique({
      where: { email: email.trim().toLowerCase() },
    });
    if (!user || !user.is_active || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ message: "Invalid email or password" });
    }
    await prisma.users.update({
      where: { user_id: user.user_id },
      data: { last_login_at: new Date() },
    });
    res.json({ token: createToken(user), user: publicUser(user) });
  } catch (error) {
    console.error("Login failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

// Generic response used for both the "email exists" and "email doesn't
// exist" cases below — this stops a bad actor from using this endpoint to
// discover which emails are registered (same idea already baked into the
// Flutter screen's copy: "If an account exists for that email...").
const GENERIC_FORGOT_PASSWORD_MESSAGE =
  "If an account exists for that email, a reset code has been sent.";

exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!validEmail(email)) {
      return res.status(400).json({ message: "A valid email is required" });
    }

    const user = await prisma.users.findUnique({
      where: { email: email.trim().toLowerCase() },
    });

    // Same response whether or not the user exists — only the internal
    // behavior differs.
    if (!user || !user.is_active) {
      return res.json({ message: GENERIC_FORGOT_PASSWORD_MESSAGE });
    }

    // 6-digit numeric code, zero-padded (e.g. "004821"), valid for 15 min.
    const code = crypto.randomInt(0, 1000000).toString().padStart(6, "0");
    const codeHash = await bcrypt.hash(code, 10);
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await prisma.users.update({
      where: { user_id: user.user_id },
      data: { reset_code_hash: codeHash, reset_code_expires_at: expiresAt },
    });

    try {
      await sendResetCodeEmail(user.email, code);
    } catch (emailError) {
      // Log the real reason server-side, but still return the generic
      // message — the client shouldn't be able to tell email sending
      // failed vs. the account not existing.
      console.error("Sending reset code email failed:", emailError.message);
    }

    res.json({ message: GENERIC_FORGOT_PASSWORD_MESSAGE });
  } catch (error) {
    console.error("Forgot password failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const { email, code, new_password } = req.body;
    if (
      !validEmail(email) ||
      typeof code !== "string" || !/^\d{6}$/.test(code) ||
      typeof new_password !== "string" || new_password.length < 8
    ) {
      return res.status(400).json({
        message: "A valid email, 6-digit code, and a new password of at least 8 characters are required",
      });
    }

    const user = await prisma.users.findUnique({
      where: { email: email.trim().toLowerCase() },
    });

    if (!user || !user.reset_code_hash || !user.reset_code_expires_at) {
      return res.status(400).json({ message: "Invalid or expired code" });
    }
    if (new Date() > user.reset_code_expires_at) {
      return res.status(400).json({ message: "Invalid or expired code" });
    }
    if (!(await bcrypt.compare(code, user.reset_code_hash))) {
      return res.status(400).json({ message: "Invalid or expired code" });
    }

    const newHash = await bcrypt.hash(new_password, 10);
    await prisma.users.update({
      where: { user_id: user.user_id },
      data: {
        password_hash: newHash,
        reset_code_hash: null,
        reset_code_expires_at: null,
      },
    });

    res.json({ message: "Password updated successfully" });
  } catch (error) {
    console.error("Reset password failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};
