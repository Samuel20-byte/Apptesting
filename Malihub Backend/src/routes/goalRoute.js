const express = require("express");
const auth = require("../middleware/authMiddleware");
const goalController = require("../controllers/goalController");

const router = express.Router();
router.get("/", auth, goalController.list);
module.exports = router;
