require("dotenv").config();

// A configured secret keeps tokens valid across restarts. The fallback keeps
// local development usable when an older .env only has DATABASE_URL.
if (!process.env.JWT_SECRET) {
  process.env.JWT_SECRET = require("crypto").randomBytes(48).toString("hex");
  console.warn("JWT_SECRET is not set; existing sessions will end when the server restarts.");
}

const express = require("express");
const cors = require("cors");
const authRoutes = require("./routes/authRoute");
const userRoutes = require("./routes/userRoute");
const accountRoutes = require("./routes/accountRoute");
const transactionRoutes = require("./routes/transactionRoute");
const goalRoutes = require("./routes/goalRoute");
const categoryRoutes = require("./routes/categoryRoute");
const budgetRoutes = require("./routes/budgetRoute");
const notificationRoutes = require("./routes/notificationRoute");

const app = express();
app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/accounts", accountRoutes);
app.use("/api/transactions", transactionRoutes);
app.use("/api/goals", goalRoutes);
app.use("/api/categories", categoryRoutes);
app.use("/api/budgets", budgetRoutes);
app.use("/api/notifications", notificationRoutes);

app.get("/", (req, res) => {
  res.send("Malihub Backend is running");
});

module.exports = app;

// Supports launching this file directly from an IDE as well as via server.js.
if (require.main === module) {
  const port = Number(process.env.PORT) || 5000;
  app.listen(port, "0.0.0.0", () => {
    console.log(`Malihub API listening on port ${port}`);
  });
}
