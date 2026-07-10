const app = require("./app");

const port = Number(process.env.PORT) || 5000;
app.listen(port, "0.0.0.0", () => {
  console.log(`Malihub API listening on port ${port}`);
});
