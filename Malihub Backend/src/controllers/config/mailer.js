const { Resend } = require("resend");

// Railway blocks outbound SMTP (ports 465/587) with IPv6 ENETUNREACH errors,
// so we send over Resend's HTTP API instead — same idea as JWT_SECRET, set
// RESEND_API_KEY as a Railway service variable. Get a key from
// https://resend.com/api-keys
const resend = new Resend(process.env.RESEND_API_KEY);

// Resend's shared sandbox address works without verifying your own domain,
// but on the free tier it will only deliver to the email address you signed
// up to Resend with — fine for an IBL demo. Once/if you verify a real
// domain in Resend, set EMAIL_FROM to something like
// "Malihub <noreply@yourdomain.com>" instead.
const FROM_ADDRESS = process.env.EMAIL_FROM || "Malihub <onboarding@resend.dev>";

/**
 * Sends the 6-digit password reset code to the user's email.
 * Throws if sending fails — the caller decides how to handle that
 * (logging it server-side without leaking details to the client).
 */
async function sendResetCodeEmail(toEmail, code) {
  const { error } = await resend.emails.send({
    from: FROM_ADDRESS,
    to: toEmail,
    subject: "Your Malihub password reset code",
    text: `Your password reset code is ${code}. It expires in 15 minutes. If you didn't request this, you can safely ignore this email.`,
    html: `
      <p>Your password reset code is:</p>
      <p style="font-size: 28px; font-weight: bold; letter-spacing: 4px;">${code}</p>
      <p>This code expires in 15 minutes. If you didn't request this, you can safely ignore this email.</p>
    `,
  });

  if (error) {
    throw new Error(error.message || "Resend failed to send email");
  }
}

module.exports = { sendResetCodeEmail };