const nodemailer = require("nodemailer");

// Reads from environment variables — set locally in .env for testing, and
// on Railway as service variables, the same way JWT_SECRET is configured.
// EMAIL_USER: the Gmail address itself (e.g. malihub.app@gmail.com)
// EMAIL_APP_PASSWORD: the 16-character App Password (NOT the normal Gmail
// login password) generated from https://myaccount.google.com/apppasswords
const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 587,
  secure: false, // STARTTLS — port 465 (implicit SSL) is blocked on some hosts
  family: 4, // force IPv4 — the IPv6 route appears unreachable on Railway
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_APP_PASSWORD,
  },
});

/**
 * Sends the 6-digit password reset code to the user's email.
 * Throws if sending fails — the caller decides how to handle that
 * (logging it server-side without leaking details to the client).
 */
async function sendResetCodeEmail(toEmail, code) {
  await transporter.sendMail({
    from: `"Malihub" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: "Your Malihub password reset code",
    text: `Your password reset code is ${code}. It expires in 15 minutes. If you didn't request this, you can safely ignore this email.`,
    html: `
      <p>Your password reset code is:</p>
      <p style="font-size: 28px; font-weight: bold; letter-spacing: 4px;">${code}</p>
      <p>This code expires in 15 minutes. If you didn't request this, you can safely ignore this email.</p>
    `,
  });
}

module.exports = { sendResetCodeEmail };