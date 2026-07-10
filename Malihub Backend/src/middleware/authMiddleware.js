const jwt = require("jsonwebtoken");

module.exports = (req, res, next) => {
  const authorization = req.get("authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Authentication token is required" });
  }
  try {
    req.auth = jwt.verify(authorization.slice(7), process.env.JWT_SECRET);
    next();
  } catch (_) {
    return res.status(401).json({ message: "Invalid or expired authentication token" });
  }
};
