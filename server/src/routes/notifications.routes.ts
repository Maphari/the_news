import { Router } from 'express';
import { verifyToken } from '../middleware/auth.middleware';
import {
  registerToken,
  unregisterToken,
  savePreferences,
  getPreferences,
  sendBreakingNews,
  sendPublisherUpdate,
  sendCommentReply,
  sendDailyDigest,
  sendTestNotification,
  saveNotificationHistory,
  getNotificationHistory,
  markNotificationAsRead,
  deleteNotificationHistory,
  clearAllNotifications,
  getUnreadCount,
  cleanupOldNotifications,
  cleanupReadNotifications,
} from '../controllers/notifications.controller';

const notificationsRouter: Router = Router();

// Token management
notificationsRouter.post('/register', registerToken);
notificationsRouter.post('/unregister', unregisterToken);

// Preferences management
notificationsRouter.post('/preferences', verifyToken, savePreferences);
notificationsRouter.get('/preferences/:userId', verifyToken, getPreferences);

// Send notifications (protected - should be called by backend services)
notificationsRouter.post('/breaking-news', verifyToken, sendBreakingNews);
notificationsRouter.post('/publisher-update', sendPublisherUpdate);
notificationsRouter.post('/comment-reply', sendCommentReply);
notificationsRouter.post('/daily-digest', sendDailyDigest);

// Test notification
notificationsRouter.post('/test', verifyToken, sendTestNotification);

// Notification history management
notificationsRouter.post('/history', saveNotificationHistory);
notificationsRouter.get('/history/:userId', getNotificationHistory);
notificationsRouter.patch('/history/:notificationId/read', markNotificationAsRead);
notificationsRouter.delete('/history/:notificationId', deleteNotificationHistory);
notificationsRouter.delete('/history/user/:userId', clearAllNotifications);
notificationsRouter.get('/history/:userId/unread-count', getUnreadCount);

// Cleanup endpoints
notificationsRouter.delete('/cleanup', cleanupOldNotifications);
notificationsRouter.delete('/cleanup/:userId/read', cleanupReadNotifications);

export default notificationsRouter;
