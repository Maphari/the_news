import { Router } from 'express';
import { verifyToken } from '../middleware/auth.middleware';
import {
  getSubscriptionStatus,
  initializePayment,
  savePendingSubscription,
  verifyPayment,
  handlePaystackCallback,
  cancelSubscription,
  getPaymentHistory,
  cleanupExpiredSubscriptions,
  updateSubscription,
} from '../controllers/subscriptions.controller';

const subscriptionsRouter: Router = Router();

// Get subscription status
subscriptionsRouter.get('/:userId', getSubscriptionStatus);

// Update subscription (for trial activation, status changes, etc.)
subscriptionsRouter.put('/:userId', updateSubscription);

// Initialize payment with Paystack
subscriptionsRouter.post('/initialize', initializePayment);

// Save pending subscription before payment
subscriptionsRouter.post('/pending', savePendingSubscription);

// Verify payment and activate subscription
subscriptionsRouter.post('/verify', verifyPayment);

// Paystack webhook callback (no auth required)
subscriptionsRouter.post('/callback', handlePaystackCallback);

// Cancel subscription
subscriptionsRouter.post('/cancel', verifyToken, cancelSubscription);

// Get payment history
subscriptionsRouter.get('/history/:userId', verifyToken, getPaymentHistory);

// Cleanup expired subscriptions (cron job - should be protected in production)
subscriptionsRouter.post('/cleanup', cleanupExpiredSubscriptions);

export default subscriptionsRouter;
