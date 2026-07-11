const express = require("express");
const auth = require("../middleware/authMiddleware");
const goalController = require("../controllers/goalController");

const router = express.Router();
router.use(auth);
router.get("/", goalController.list);
router.post("/", goalController.create);
router.put("/:goalId", goalController.update);
router.patch("/:goalId/contribute", goalController.contribute);
router.delete("/:goalId", goalController.remove);
module.exports = router;
