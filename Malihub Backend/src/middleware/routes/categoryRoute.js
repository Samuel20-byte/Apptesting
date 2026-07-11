const express = require("express");
const auth = require("../authMiddleware");
const categoryController = require("../../controllers/categoryController");

const router = express.Router();
router.use(auth);
router.get("/", categoryController.list);
router.post("/", categoryController.create);
module.exports = router;
