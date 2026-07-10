const prisma = require("./config/prisma");

async function ownedNotification(id, userId) {
  const notificationId = Number.parseInt(id, 10);
  if (!Number.isInteger(notificationId)) return null;
  return prisma.notifications.findFirst({
    where: { notification_id: notificationId, user_id: userId },
  });
}

exports.list = async (req, res) => {
  try {
    const notifications = await prisma.notifications.findMany({
      where: { user_id: req.auth.user_id },
      orderBy: { created_at: "desc" },
    });
    res.json(notifications);
  } catch (error) {
    console.error("List notifications failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.markRead = async (req, res) => {
  try {
    const notification = await ownedNotification(req.params.notificationId, req.auth.user_id);
    if (!notification) return res.status(404).json({ message: "Notification not found" });
    res.json(await prisma.notifications.update({
      where: { notification_id: notification.notification_id },
      data: { is_read: true },
    }));
  } catch (error) {
    console.error("Mark notification read failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.markAllRead = async (req, res) => {
  try {
    await prisma.notifications.updateMany({
      where: { user_id: req.auth.user_id, is_read: false },
      data: { is_read: true },
    });
    res.status(204).end();
  } catch (error) {
    console.error("Mark all notifications read failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

exports.remove = async (req, res) => {
  try {
    const notification = await ownedNotification(req.params.notificationId, req.auth.user_id);
    if (!notification) return res.status(404).json({ message: "Notification not found" });
    await prisma.notifications.delete({ where: { notification_id: notification.notification_id } });
    res.status(204).end();
  } catch (error) {
    console.error("Delete notification failed:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};
