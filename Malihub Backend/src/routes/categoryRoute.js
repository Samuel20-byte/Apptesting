const express = require("express");
const auth = require("../middleware/authMiddleware");
const categoryController = require("../controllers/categoryController");

const router = express.Router();
router.use(auth);
router.gets("/", categoryController.list);
router.post("/", categoryController.create);
router.delete("/:categoryId", categoryController.remove);
module.exports = router;
