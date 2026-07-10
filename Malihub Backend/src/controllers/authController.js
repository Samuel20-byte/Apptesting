const bcrypt = require("bcrypt");
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

exports.register = async (req, res) => {
  try {
    const {
      first_name,
      last_name,
      email,
      phone_number,
      password
    } = req.body;

    const existingUser = await prisma.users.findUnique({
      where: { email }
    });

    if (existingUser) {
      return res.status(400).json({
        message: "Email already exists"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await prisma.users.create({
      data: {
        first_name,
        last_name,
        email,
        phone_number,
        password_hash: hashedPassword
      }
    });

    res.status(201).json({
      message: "User registered successfully",
      user
    });

  } catch (error) {
    console.log(error);
    res.status(500).json({
      message: "Server error"
    });
  }
};