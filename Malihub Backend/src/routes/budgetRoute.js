const express = require("express");
const auth = require("../middleware/authMiddleware");
const budgetController = require("../controllers/budgetController");

const router = express.Router();
router.use(auth);
router.get("/", budgetController.list);
router.post("/", budgetController.create);
router.put("/:budgetId", budgetController.update);
router.delete("/:budgetId", budgetController.remove);
module.exports = router;
