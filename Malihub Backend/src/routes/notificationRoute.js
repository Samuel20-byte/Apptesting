const express = require("express");
const auth = require("../middleware/authMiddleware");
const notificationController = require("../controllers/notificationController");

const router = express.Router();
router.use(auth);
router.get("/", notificationController.list);
router.patch("/read-all", notificationController.markAllRead);
router.patch("/:notificationId/read", notificationController.markRead);
router.delete("/:notificationId", notificationController.remove);
module.exports = router;
