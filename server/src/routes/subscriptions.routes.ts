import { Router } from 'express';
import { verifyToken } from '../middleware/auth.middleware';
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from '../middleware/cache.middleware';
import {
  getSubscriptionStatus,
  initializePayment,
  savePendingSubscription,
  verifyPayment,
  handlePaystackCallback,
  cancelSubscription,
  getPaymentHistory,
  getPaymentMethods,
  setDefaultPaymentMethod,
  removePaymentMethod,
  cleanupExpiredSubscriptions,
  updateSubscription,
} from '../controllers/subscriptions.controller';

const subscriptionsRouter: Router = Router();
const subscriptionStatusReadCache = cacheResponse({
  namespace: 'subscription-status',
  ttlSeconds: 60,
});
const subscriptionBillingReadCache = cacheResponse({
  namespace: 'subscription-billing',
  ttlSeconds: 300,
});
const invalidateSubscriptionCache = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return ['subscription-status:uid:_:', 'subscription-billing:uid:_:'];
  }
  return userIds.flatMap((id) => [
    `subscription-status:uid:${id}:`,
    `subscription-billing:uid:${id}:`,
  ]);
});

// Initialize payment with Paystack
subscriptionsRouter.post('/initialize', invalidateSubscriptionCache, initializePayment);

// Save pending subscription before payment
subscriptionsRouter.post('/pending', invalidateSubscriptionCache, savePendingSubscription);

// Verify payment and activate subscription
subscriptionsRouter.post('/verify', invalidateSubscriptionCache, verifyPayment);

// Paystack webhook callback (no auth required)
subscriptionsRouter.post('/callback', invalidateSubscriptionCache, handlePaystackCallback);

// Cancel subscription
subscriptionsRouter.post('/cancel', verifyToken, invalidateSubscriptionCache, cancelSubscription);

// Get payment history
subscriptionsRouter.get(
  '/history/:userId',
  verifyToken,
  subscriptionBillingReadCache,
  getPaymentHistory
);

// Get payment methods
subscriptionsRouter.get(
  '/payment-methods/:userId',
  verifyToken,
  subscriptionBillingReadCache,
  getPaymentMethods
);

// Set default payment method
subscriptionsRouter.put(
  '/payment-methods/:userId/default',
  verifyToken,
  invalidateSubscriptionCache,
  setDefaultPaymentMethod
);

// Remove payment method
subscriptionsRouter.delete(
  '/payment-methods/:userId',
  verifyToken,
  invalidateSubscriptionCache,
  removePaymentMethod
);

// Get subscription status
subscriptionsRouter.get('/:userId', subscriptionStatusReadCache, getSubscriptionStatus);

// Update subscription (for trial activation, status changes, etc.)
subscriptionsRouter.put('/:userId', invalidateSubscriptionCache, updateSubscription);

// Cleanup expired subscriptions (cron job - should be protected in production)
subscriptionsRouter.post('/cleanup', invalidateSubscriptionCache, cleanupExpiredSubscriptions);

export default subscriptionsRouter;
