import { Request, Response } from 'express';
import { db } from '../config/firebase.connection';
import * as admin from 'firebase-admin';

/**
 * Register FCM token for a user
 * POST /api/v1/notifications/register
 */
export const registerToken = async (req: Request, res: Response) => {
  try {
    const { token, userId, platform } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required',
      });
    }

    // Store token in Firestore
    const tokenRef = db.collection('fcmTokens').doc(token);
    await tokenRef.set({
      token,
      userId: userId || null,
      platform: platform || 'unknown',
      createdAt: new Date(),
      lastUsed: new Date(),
    });

    console.log(`✅ FCM token registered: ${token.substring(0, 20)}...`);

    return res.status(200).json({
      success: true,
      message: 'Token registered successfully',
    });
  } catch (error: any) {
    console.error('❌ Register token error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to register token',
      error: error.message,
    });
  }
};

/**
 * Unregister FCM token (on logout)
 * POST /api/v1/notifications/unregister
 */
export const unregisterToken = async (req: Request, res: Response) => {
  try {
    const { token, userId } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required',
      });
    }

    // Delete token from Firestore
    await db.collection('fcmTokens').doc(token).delete();

    console.log(`✅ FCM token unregistered for user: ${userId}`);

    return res.status(200).json({
      success: true,
      message: 'Token unregistered successfully',
    });
  } catch (error: any) {
    console.error('❌ Unregister token error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to unregister token',
      error: error.message,
    });
  }
};

/**
 * Save notification preferences for a user
 * POST /api/v1/notifications/preferences
 */
export const savePreferences = async (req: Request, res: Response) => {
  try {
    const { userId, breakingNews, dailyDigest, publisherUpdates, commentReplies } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID is required',
      });
    }

    // Save preferences to Firestore
    const preferencesRef = db.collection('notificationPreferences').doc(userId);
    await preferencesRef.set({
      userId,
      breakingNews: breakingNews ?? true,
      dailyDigest: dailyDigest ?? true,
      publisherUpdates: publisherUpdates ?? true,
      commentReplies: commentReplies ?? true,
      updatedAt: new Date(),
    });

    console.log(`✅ Notification preferences saved for user: ${userId}`);

    return res.status(200).json({
      success: true,
      message: 'Preferences saved successfully',
    });
  } catch (error: any) {
    console.error('❌ Save preferences error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to save preferences',
      error: error.message,
    });
  }
};

/**
 * Get notification preferences for a user
 * GET /api/v1/notifications/preferences/:userId
 */
export const getPreferences = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const preferencesDoc = await db.collection('notificationPreferences').doc(userId).get();

    if (!preferencesDoc.exists) {
      // Return default preferences
      return res.status(200).json({
        success: true,
        preferences: {
          breakingNews: true,
          dailyDigest: true,
          publisherUpdates: true,
          commentReplies: true,
        },
      });
    }

    return res.status(200).json({
      success: true,
      preferences: preferencesDoc.data(),
    });
  } catch (error: any) {
    console.error('❌ Get preferences error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to get preferences',
      error: error.message,
    });
  }
};

/**
 * Send breaking news notification to all users
 * POST /api/v1/notifications/breaking-news
 */
export const sendBreakingNews = async (req: Request, res: Response) => {
  try {
    const { title, body, articleId, imageUrl } = req.body;

    if (!title || !body) {
      return res.status(400).json({
        success: false,
        message: 'Title and body are required',
      });
    }

    // Send to "breaking_news" topic (users subscribe to this)
    const message: admin.messaging.Message = {
      notification: {
        title: `🚨 ${title}`,
        body,
        imageUrl,
      },
      data: {
        type: 'breaking_news',
        articleId: articleId || '',
      },
      topic: 'breaking_news',
      android: {
        priority: 'high',
        notification: {
          channelId: 'breaking_news',
          priority: 'max',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            contentAvailable: true,
          },
        },
      },
    };

    const messageId = await admin.messaging().send(message);

    console.log(`🚨 Breaking news sent: ${messageId}`);

    // Save to notification history for all users subscribed to breaking news topic
    // Note: We'll save individual history records when users receive the notification
    // through the client-side FCM handler

    return res.status(200).json({
      success: true,
      message: 'Breaking news notification sent',
      messageId,
    });
  } catch (error: any) {
    console.error('❌ Send breaking news error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to send breaking news',
      error: error.message,
    });
  }
};

/**
 * Send publisher update notification to followers
 * POST /api/v1/notifications/publisher-update
 */
export const sendPublisherUpdate = async (req: Request, res: Response) => {
  try {
    const { publisherId, publisherName, articleTitle, articleId } = req.body;

    if (!publisherId || !publisherName || !articleTitle) {
      return res.status(400).json({
        success: false,
        message: 'Publisher ID, name, and article title are required',
      });
    }

    // Get followers of this publisher
    const followersSnapshot = await db
      .collection('followedPublishers')
      .where('publisherId', '==', publisherId)
      .get();

    if (followersSnapshot.empty) {
      return res.status(200).json({
        success: true,
        message: 'No followers to notify',
        sentCount: 0,
      });
    }

    const userIds = followersSnapshot.docs.map((doc) => doc.data().userId);

    // Get FCM tokens for these users
    const tokensSnapshot = await db
      .collection('fcmTokens')
      .where('userId', 'in', userIds)
      .get();

    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);

    if (tokens.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'No tokens found for followers',
        sentCount: 0,
      });
    }

    // Check preferences and filter users
    const preferencesSnapshot = await db
      .collection('notificationPreferences')
      .where('userId', 'in', userIds)
      .get();

    const allowedUserIds = new Set<string>();
    preferencesSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.publisherUpdates !== false) {
        allowedUserIds.add(data.userId);
      }
    });

    // Filter tokens by allowed users
    const filteredTokens: string[] = [];
    for (const doc of tokensSnapshot.docs) {
      if (allowedUserIds.has(doc.data().userId) || !preferencesSnapshot.size) {
        filteredTokens.push(doc.data().token);
      }
    }

    if (filteredTokens.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'All users have disabled publisher notifications',
        sentCount: 0,
      });
    }

    // Send multicast message
    const message: admin.messaging.MulticastMessage = {
      notification: {
        title: `📰 New from ${publisherName}`,
        body: articleTitle,
      },
      data: {
        type: 'publisher_update',
        articleId: articleId || '',
        publisherId,
      },
      tokens: filteredTokens,
      android: {
        notification: {
          channelId: 'publisher_updates',
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    console.log(`📰 Publisher update sent to ${response.successCount} users`);

    return res.status(200).json({
      success: true,
      message: 'Publisher update notifications sent',
      sentCount: response.successCount,
      failureCount: response.failureCount,
    });
  } catch (error: any) {
    console.error('❌ Send publisher update error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to send publisher update',
      error: error.message,
    });
  }
};

/**
 * Send comment reply notification
 * POST /api/v1/notifications/comment-reply
 */
export const sendCommentReply = async (req: Request, res: Response) => {
  try {
    const { originalCommentUserId, commenterName, replyText, articleId, commentId } = req.body;

    if (!originalCommentUserId || !commenterName || !replyText) {
      return res.status(400).json({
        success: false,
        message: 'Original comment user ID, commenter name, and reply text are required',
      });
    }

    // Check if user has comment reply notifications enabled
    const preferencesDoc = await db
      .collection('notificationPreferences')
      .doc(originalCommentUserId)
      .get();

    if (preferencesDoc.exists && preferencesDoc.data()?.commentReplies === false) {
      return res.status(200).json({
        success: true,
        message: 'User has disabled comment reply notifications',
      });
    }

    // Get FCM token for the user
    const tokensSnapshot = await db
      .collection('fcmTokens')
      .where('userId', '==', originalCommentUserId)
      .limit(1)
      .get();

    if (tokensSnapshot.empty) {
      return res.status(200).json({
        success: true,
        message: 'No token found for user',
      });
    }

    const token = tokensSnapshot.docs[0].data().token;

    // Send notification
    const message: admin.messaging.Message = {
      notification: {
        title: `💬 ${commenterName} replied`,
        body: replyText,
      },
      data: {
        type: 'comment_reply',
        articleId: articleId || '',
        commentId: commentId || '',
      },
      token,
      android: {
        notification: {
          channelId: 'comment_replies',
        },
      },
    };

    const messageId = await admin.messaging().send(message);

    console.log(`💬 Comment reply notification sent: ${messageId}`);

    return res.status(200).json({
      success: true,
      message: 'Comment reply notification sent',
      messageId,
    });
  } catch (error: any) {
    console.error('❌ Send comment reply error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to send comment reply notification',
      error: error.message,
    });
  }
};

/**
 * Send daily digest notification to a user
 * POST /api/v1/notifications/daily-digest
 */
export const sendDailyDigest = async (req: Request, res: Response) => {
  try {
    const { userId, title, itemCount, estimatedMinutes } = req.body;

    if (!userId || !title) {
      return res.status(400).json({
        success: false,
        message: 'User ID and title are required',
      });
    }

    // Check if user has daily digest notifications enabled
    const preferencesDoc = await db
      .collection('notificationPreferences')
      .doc(userId)
      .get();

    if (preferencesDoc.exists && preferencesDoc.data()?.dailyDigest === false) {
      return res.status(200).json({
        success: true,
        message: 'User has disabled daily digest notifications',
      });
    }

    // Get FCM token for the user
    const tokensSnapshot = await db
      .collection('fcmTokens')
      .where('userId', '==', userId)
      .limit(1)
      .get();

    if (tokensSnapshot.empty) {
      return res.status(200).json({
        success: true,
        message: 'No token found for user',
      });
    }

    const token = tokensSnapshot.docs[0].data().token;

    // Send notification
    const message: admin.messaging.Message = {
      notification: {
        title: `📰 ${title}`,
        body: `${itemCount} stories • ${estimatedMinutes} min read`,
      },
      data: {
        type: 'daily_digest',
      },
      token,
      android: {
        notification: {
          channelId: 'daily_digest_channel',
        },
      },
    };

    const messageId = await admin.messaging().send(message);

    console.log(`📰 Daily digest notification sent: ${messageId}`);

    return res.status(200).json({
      success: true,
      message: 'Daily digest notification sent',
      messageId,
    });
  } catch (error: any) {
    console.error('❌ Send daily digest error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to send daily digest notification',
      error: error.message,
    });
  }
};

/**
 * Test notification endpoint
 * POST /api/v1/notifications/test
 */
export const sendTestNotification = async (req: Request, res: Response) => {
  try {
    const { userId, title, body } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID is required',
      });
    }

    // Get FCM token for the user
    const tokensSnapshot = await db
      .collection('fcmTokens')
      .where('userId', '==', userId)
      .limit(1)
      .get();

    if (tokensSnapshot.empty) {
      return res.status(404).json({
        success: false,
        message: 'No token found for user',
      });
    }

    const token = tokensSnapshot.docs[0].data().token;

    // Send test notification
    const message: admin.messaging.Message = {
      notification: {
        title: title || 'Test Notification',
        body: body || 'This is a test notification from The News app',
      },
      data: {
        type: 'test',
      },
      token,
    };

    const messageId = await admin.messaging().send(message);

    console.log(`🧪 Test notification sent: ${messageId}`);

    return res.status(200).json({
      success: true,
      message: 'Test notification sent',
      messageId,
    });
  } catch (error: any) {
    console.error('❌ Send test notification error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to send test notification',
      error: error.message,
    });
  }
};

/**
 * Save notification to history
 * POST /api/v1/notifications/history
 */
export const saveNotificationHistory = async (req: Request, res: Response) => {
  try {
    const { userId, type, title, body, imageUrl, articleId, commentId, publisherId } = req.body;

    if (!userId || !type || !title || !body) {
      return res.status(400).json({
        success: false,
        message: 'User ID, type, title, and body are required',
      });
    }

    // Create notification history document
    const notificationRef = db.collection('notificationHistory').doc();
    await notificationRef.set({
      id: notificationRef.id,
      userId,
      type,
      title,
      body,
      imageUrl: imageUrl || null,
      articleId: articleId || null,
      commentId: commentId || null,
      publisherId: publisherId || null,
      read: false,
      timestamp: new Date(),
    });

    console.log(`💾 Notification saved to history for user: ${userId}`);

    return res.status(200).json({
      success: true,
      message: 'Notification saved to history',
      notificationId: notificationRef.id,
    });
  } catch (error: any) {
    console.error('❌ Save notification history error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to save notification history',
      error: error.message,
    });
  }
};

/**
 * Get notification history for a user
 * GET /api/v1/notifications/history/:userId
 */
export const getNotificationHistory = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const { limit = '50' } = req.query;

    const notificationsSnapshot = await db
      .collection('notificationHistory')
      .where('userId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(parseInt(limit as string))
      .get();

    const notifications = notificationsSnapshot.docs.map((doc) => doc.data());

    return res.status(200).json({
      success: true,
      notifications,
      count: notifications.length,
    });
  } catch (error: any) {
    console.error('❌ Get notification history error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to get notification history',
      error: error.message,
    });
  }
};

/**
 * Mark notification as read
 * PATCH /api/v1/notifications/history/:notificationId/read
 */
export const markNotificationAsRead = async (req: Request, res: Response) => {
  try {
    const { notificationId } = req.params;

    await db.collection('notificationHistory').doc(notificationId).update({
      read: true,
      readAt: new Date(),
    });

    console.log(`✅ Notification marked as read: ${notificationId}`);

    return res.status(200).json({
      success: true,
      message: 'Notification marked as read',
    });
  } catch (error: any) {
    console.error('❌ Mark notification as read error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to mark notification as read',
      error: error.message,
    });
  }
};

/**
 * Delete a notification from history
 * DELETE /api/v1/notifications/history/:notificationId
 */
export const deleteNotificationHistory = async (req: Request, res: Response) => {
  try {
    const { notificationId } = req.params;

    await db.collection('notificationHistory').doc(notificationId).delete();

    console.log(`🗑️ Notification deleted: ${notificationId}`);

    return res.status(200).json({
      success: true,
      message: 'Notification deleted',
    });
  } catch (error: any) {
    console.error('❌ Delete notification error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to delete notification',
      error: error.message,
    });
  }
};

/**
 * Clear all notifications for a user
 * DELETE /api/v1/notifications/history/user/:userId
 */
export const clearAllNotifications = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    // Get all notifications for the user
    const notificationsSnapshot = await db
      .collection('notificationHistory')
      .where('userId', '==', userId)
      .get();

    // Delete in batches (Firestore limit: 500 writes per batch)
    const batch = db.batch();
    let count = 0;

    notificationsSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      count++;
    });

    await batch.commit();

    console.log(`🗑️ Cleared ${count} notifications for user: ${userId}`);

    return res.status(200).json({
      success: true,
      message: 'All notifications cleared',
      deletedCount: count,
    });
  } catch (error: any) {
    console.error('❌ Clear all notifications error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to clear notifications',
      error: error.message,
    });
  }
};

/**
 * Get unread notification count for a user
 * GET /api/v1/notifications/history/:userId/unread-count
 */
export const getUnreadCount = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const notificationsSnapshot = await db
      .collection('notificationHistory')
      .where('userId', '==', userId)
      .where('read', '==', false)
      .get();

    return res.status(200).json({
      success: true,
      unreadCount: notificationsSnapshot.size,
    });
  } catch (error: any) {
    console.error('❌ Get unread count error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to get unread count',
      error: error.message,
    });
  }
};

/**
 * Cleanup old notifications (older than specified days)
 * DELETE /api/v1/notifications/cleanup
 */
export const cleanupOldNotifications = async (req: Request, res: Response) => {
  try {
    const { daysOld = '30' } = req.query;
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - parseInt(daysOld as string));

    // Get old notifications
    const oldNotificationsSnapshot = await db
      .collection('notificationHistory')
      .where('timestamp', '<', cutoffDate)
      .get();

    if (oldNotificationsSnapshot.empty) {
      return res.status(200).json({
        success: true,
        message: 'No old notifications to clean up',
        deletedCount: 0,
      });
    }

    // Delete in batches (Firestore limit: 500 writes per batch)
    const batchSize = 500;
    let totalDeleted = 0;

    for (let i = 0; i < oldNotificationsSnapshot.docs.length; i += batchSize) {
      const batch = db.batch();
      const batchDocs = oldNotificationsSnapshot.docs.slice(i, i + batchSize);

      batchDocs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      totalDeleted += batchDocs.length;
    }

    console.log(`🗑️ Cleaned up ${totalDeleted} notifications older than ${daysOld} days`);

    return res.status(200).json({
      success: true,
      message: `Cleaned up ${totalDeleted} old notifications`,
      deletedCount: totalDeleted,
      cutoffDate: cutoffDate.toISOString(),
    });
  } catch (error: any) {
    console.error('❌ Cleanup old notifications error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to cleanup old notifications',
      error: error.message,
    });
  }
};

/**
 * Cleanup read notifications for a user (older than specified days)
 * DELETE /api/v1/notifications/cleanup/:userId/read
 */
export const cleanupReadNotifications = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const { daysOld = '7' } = req.query;

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - parseInt(daysOld as string));

    // Get old read notifications for the user
    const oldNotificationsSnapshot = await db
      .collection('notificationHistory')
      .where('userId', '==', userId)
      .where('read', '==', true)
      .where('timestamp', '<', cutoffDate)
      .get();

    if (oldNotificationsSnapshot.empty) {
      return res.status(200).json({
        success: true,
        message: 'No old read notifications to clean up',
        deletedCount: 0,
      });
    }

    // Delete in batch
    const batch = db.batch();
    let count = 0;

    oldNotificationsSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      count++;
    });

    await batch.commit();

    console.log(`🗑️ Cleaned up ${count} read notifications for user: ${userId}`);

    return res.status(200).json({
      success: true,
      message: `Cleaned up ${count} old read notifications`,
      deletedCount: count,
    });
  } catch (error: any) {
    console.error('❌ Cleanup read notifications error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to cleanup read notifications',
      error: error.message,
    });
  }
};
