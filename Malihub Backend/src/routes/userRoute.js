const express = require("express");
const auth = require("../middleware/authMiddleware");
const userController = require("../controllers/userController");

const router = express.Router();
router.get("/me", auth, userController.getMe);
router.put("/me", auth, userController.updateMe);
router.put("/me/password", auth, userController.changePassword);
module.exports = router;
