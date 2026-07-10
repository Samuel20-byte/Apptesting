const express = require("express");
const auth = require("../middleware/authMiddleware");
const transactionController = require("../controllers/transactionController");

const router = express.Router();
router.use(auth);
router.get("/summary", transactionController.summary);
router.get("/", transactionController.list);
module.exports = router;
