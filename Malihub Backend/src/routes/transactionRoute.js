const express = require("express");
const auth = require("../middleware/authMiddleware");
const transactionController = require("../controllers/transactionController");

const router = express.Router();
router.use(auth);
router.get("/summary", transactionController.summary);
router.get("/", transactionController.list);
router.post("/", transactionController.create);
router.put("/:transactionId", transactionController.update);
router.delete("/:transactionId", transactionController.remove);
module.exports = router;
