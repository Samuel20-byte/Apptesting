const express = require("express");

const app = express();

app.use(express.json());

const authRoutes = require("./routes/authRoute");
app.use("/api/auth", authRoutes);

app.get("/", (req, res) => {
    res.send("Malihub Backend is running");
});

const PORT = 5000;

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

