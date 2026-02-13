import { Router } from 'express';
import { verifyToken } from '../middleware/auth.middleware';
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from '../middleware/cache.middleware';
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
const notificationPreferencesReadCache = cacheResponse({
  namespace: 'notification-preferences',
  ttlSeconds: 300,
});
const notificationHistoryReadCache = cacheResponse({
  namespace: 'notification-history',
  ttlSeconds: 60,
});
const invalidateNotificationCache = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return ['notification-preferences:uid:_:', 'notification-history:uid:_:'];
  }
  return userIds.flatMap((id) => [
    `notification-preferences:uid:${id}:`,
    `notification-history:uid:${id}:`,
  ]);
});

// Token management
notificationsRouter.post('/register', invalidateNotificationCache, registerToken);
notificationsRouter.post('/unregister', invalidateNotificationCache, unregisterToken);

// Preferences management
notificationsRouter.post('/preferences', verifyToken, invalidateNotificationCache, savePreferences);
notificationsRouter.get(
  '/preferences/:userId',
  verifyToken,
  notificationPreferencesReadCache,
  getPreferences
);

// Send notifications (protected - should be called by backend services)
notificationsRouter.post('/breaking-news', verifyToken, sendBreakingNews);
notificationsRouter.post('/publisher-update', sendPublisherUpdate);
notificationsRouter.post('/comment-reply', sendCommentReply);
notificationsRouter.post('/daily-digest', sendDailyDigest);

// Test notification
notificationsRouter.post('/test', verifyToken, sendTestNotification);

// Notification history management
notificationsRouter.post('/history', invalidateNotificationCache, saveNotificationHistory);
notificationsRouter.get('/history/:userId', notificationHistoryReadCache, getNotificationHistory);
notificationsRouter.patch('/history/:notificationId/read', invalidateNotificationCache, markNotificationAsRead);
notificationsRouter.delete('/history/:notificationId', invalidateNotificationCache, deleteNotificationHistory);
notificationsRouter.delete('/history/user/:userId', invalidateNotificationCache, clearAllNotifications);
notificationsRouter.get('/history/:userId/unread-count', notificationHistoryReadCache, getUnreadCount);

// Cleanup endpoints
notificationsRouter.delete('/cleanup', invalidateNotificationCache, cleanupOldNotifications);
notificationsRouter.delete('/cleanup/:userId/read', invalidateNotificationCache, cleanupReadNotifications);

export default notificationsRouter;
