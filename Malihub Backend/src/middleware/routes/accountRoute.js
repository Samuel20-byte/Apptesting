const express = require("express");
const auth = require("../middleware/authMiddleware");
const accountController = require("../controllers/accountController");

const router = express.Router();
router.use(auth);
router.get("/", accountController.list);
router.post("/", accountController.create);
module.exports = router;
