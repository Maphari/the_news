import { Request, Response } from 'express';
import { db } from '../config/firebase.connection';
import Paystack from 'paystack-node';

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY || '';
const paystack = new Paystack(PAYSTACK_SECRET_KEY);

/**
 * Get subscription status for a user
 * GET /api/v1/subscriptions/:userId
 */
export const getSubscriptionStatus = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const subscriptionRef = db.collection('subscriptions').doc(userId);
    const subscriptionDoc = await subscriptionRef.get();

    if (!subscriptionDoc.exists) {
      return res.status(200).json({
        success: true,
        isPremium: false,
        subscriptionType: null,
        subscriptionEndDate: null,
        subscription: null,
      });
    }

    const subscription = subscriptionDoc.data();
    const now = new Date();
    const endDate = subscription?.subscriptionEndDate?.toDate();

    // Check if subscription is still active
    const isActive = endDate && endDate > now;

    return res.status(200).json({
      success: true,
      isPremium: isActive,
      subscriptionType: isActive ? subscription?.subscriptionType : null,
      subscriptionEndDate: isActive ? endDate.toISOString() : null,
      autoRenew: subscription?.autoRenew || false,
      subscription: subscription, // Include full subscription data for Flutter to load
    });
  } catch (error: any) {
    console.error('❌ Get subscription status error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to get subscription status',
      error: error.message,
    });
  }
};

/**
 * Update subscription (for trial activation, status changes, etc.)
 * PUT /api/v1/subscriptions/:userId
 */
export const updateSubscription = async (req: Request, res: Response) => {
  try {
    const userId = req.params.userId as string;
    const subscriptionData = req.body;

    console.log(`📝 Updating subscription for user: ${userId}`);

    // Validate required fields
    if (!subscriptionData || !subscriptionData.userId) {
      return res.status(400).json({
        success: false,
        message: 'Invalid subscription data',
      });
    }

    // Convert date strings to Firestore Timestamps
    const firestoreData: any = { ...subscriptionData };

    if (subscriptionData.trialStartDate) {
      firestoreData.trialStartDate = new Date(subscriptionData.trialStartDate);
    }
    if (subscriptionData.trialEndDate) {
      firestoreData.trialEndDate = new Date(subscriptionData.trialEndDate);
    }
    if (subscriptionData.subscriptionStartDate) {
      firestoreData.subscriptionStartDate = new Date(subscriptionData.subscriptionStartDate);
    }
    if (subscriptionData.subscriptionEndDate) {
      firestoreData.subscriptionEndDate = new Date(subscriptionData.subscriptionEndDate);
    }
    if (subscriptionData.lastResetDate) {
      firestoreData.lastResetDate = new Date(subscriptionData.lastResetDate);
    }

    // Update or create subscription document
    const subscriptionRef = db.collection('subscriptions').doc(userId);
    await subscriptionRef.set(firestoreData, { merge: true });

    console.log(`✅ Subscription updated for user: ${userId}`);

    return res.status(200).json({
      success: true,
      message: 'Subscription updated successfully',
      subscription: firestoreData,
    });
  } catch (error: any) {
    console.error('❌ Update subscription error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update subscription',
      error: error.message,
    });
  }
};

/**
 * Initialize payment with Paystack
 * POST /api/v1/subscriptions/initialize
 */
export const initializePayment = async (req: Request, res: Response) => {
  try {
    const { userId, email, amount, currency, reference, plan } = req.body;

    if (!userId || !email || !amount || !reference || !plan) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: userId, email, amount, reference, plan',
      });
    }

    console.log(`💳 Initializing payment for user ${userId}: ${plan} - ${currency} ${amount / 100}`);

    // Initialize transaction with Paystack
    const response = await paystack.transaction.initialize({
      email,
      amount,
      currency: currency || 'ZAR',
      reference,
      callback_url: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/callback`,
      metadata: {
        userId,
        plan,
        custom_fields: [
          {
            display_name: 'Subscription Plan',
            variable_name: 'plan',
            value: plan === 'monthly' ? 'Monthly Premium' : 'Yearly Premium',
          },
        ],
      },
    });

    if (response.status && response.data) {
      // Save pending subscription
      const pendingRef = db.collection('pendingSubscriptions').doc(reference);
      await pendingRef.set({
        userId,
        reference,
        plan,
        amount,
        currency,
        status: 'pending',
        createdAt: new Date(),
      });

      console.log(`✅ Payment initialized: ${response.data.authorization_url}`);

      return res.status(200).json({
        success: true,
        authorizationUrl: response.data.authorization_url,
        accessCode: response.data.access_code,
        reference,
      });
    }

    return res.status(400).json({
      success: false,
      message: 'Failed to initialize payment with Paystack',
    });
  } catch (error: any) {
    console.error('❌ Payment initialization error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to initialize payment',
      error: error.message,
    });
  }
};

/**
 * Save pending subscription (called before payment)
 * POST /api/v1/subscriptions/pending
 */
export const savePendingSubscription = async (req: Request, res: Response) => {
  try {
    const { userId, reference, plan, status } = req.body;

    if (!userId || !reference || !plan) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: userId, reference, plan',
      });
    }

    const pendingRef = db.collection('pendingSubscriptions').doc(reference);
    await pendingRef.set({
      userId,
      reference,
      plan,
      status: status || 'pending',
      createdAt: new Date(),
    });

    return res.status(200).json({
      success: true,
      message: 'Pending subscription saved',
    });
  } catch (error: any) {
    console.error('❌ Save pending subscription error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to save pending subscription',
      error: error.message,
    });
  }
};

/**
 * Verify payment and activate subscription
 * POST /api/v1/subscriptions/verify
 */
export const verifyPayment = async (req: Request, res: Response) => {
  try {
    const { reference } = req.body;

    if (!reference) {
      return res.status(400).json({
        success: false,
        message: 'Missing payment reference',
      });
    }

    // Verify payment with Paystack
    const verification = await paystack.transaction.verify({ reference });

    if (!verification.status || verification.data.status !== 'success') {
      return res.status(400).json({
        success: false,
        message: 'Payment verification failed',
      });
    }

    // Get pending subscription
    const pendingRef = db.collection('pendingSubscriptions').doc(reference);
    const pendingDoc = await pendingRef.get();

    if (!pendingDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Pending subscription not found',
      });
    }

    const pending = pendingDoc.data();
    const userId = pending?.userId;
    const plan = pending?.plan;

    // Calculate subscription end date
    const now = new Date();
    const endDate = new Date(now);
    if (plan === 'monthly') {
      endDate.setMonth(endDate.getMonth() + 1);
    } else if (plan === 'yearly') {
      endDate.setFullYear(endDate.getFullYear() + 1);
    }

    // Create or update subscription
    const subscriptionRef = db.collection('subscriptions').doc(userId);
    await subscriptionRef.set({
      userId,
      subscriptionType: plan,
      subscriptionStartDate: now,
      subscriptionEndDate: endDate,
      status: 'active',
      autoRenew: true,
      paymentReference: reference,
      paymentAmount: verification.data.amount,
      paymentCurrency: verification.data.currency,
      lastPaymentDate: now,
      updatedAt: now,
    });

    // Save payment history
    const paymentHistoryRef = db.collection('paymentHistory').doc();
    await paymentHistoryRef.set({
      userId,
      reference,
      plan,
      amount: verification.data.amount,
      currency: verification.data.currency,
      status: 'success',
      paymentDate: now,
      subscriptionStartDate: now,
      subscriptionEndDate: endDate,
    });

    // Update pending subscription status
    await pendingRef.update({
      status: 'completed',
      completedAt: now,
    });

    console.log(`✅ Subscription activated for user ${userId}: ${plan}`);

    return res.status(200).json({
      success: true,
      message: 'Payment verified and subscription activated',
      plan,
      subscriptionEndDate: endDate.toISOString(),
    });
  } catch (error: any) {
    console.error('❌ Verify payment error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to verify payment',
      error: error.message,
    });
  }
};

/**
 * Handle Paystack webhook callback
 * POST /api/v1/subscriptions/callback
 */
export const handlePaystackCallback = async (req: Request, res: Response) => {
  try {
    const event = req.body;

    // Verify webhook signature
    const hash = require('crypto')
      .createHmac('sha512', PAYSTACK_SECRET_KEY)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (hash !== req.headers['x-paystack-signature']) {
      return res.status(401).json({
        success: false,
        message: 'Invalid signature',
      });
    }

    // Handle different event types
    if (event.event === 'charge.success') {
      const reference = event.data.reference;
      const metadata = event.data.metadata;

      // Automatically verify and activate subscription
      await verifyPayment({ body: { reference } } as Request, res);
    } else if (event.event === 'subscription.disable') {
      // Handle subscription cancellation from Paystack
      const subscriptionCode = event.data.subscription_code;

      // Find and deactivate subscription
      const subscriptionsSnapshot = await db
        .collection('subscriptions')
        .where('paystackSubscriptionCode', '==', subscriptionCode)
        .get();

      subscriptionsSnapshot.forEach(async (doc) => {
        await doc.ref.update({
          status: 'cancelled',
          autoRenew: false,
          updatedAt: new Date(),
        });
      });
    }

    return res.status(200).json({ success: true });
  } catch (error: any) {
    console.error('❌ Paystack callback error:', error);
    return res.status(500).json({
      success: false,
      message: 'Callback processing failed',
      error: error.message,
    });
  }
};

/**
 * Cancel subscription
 * POST /api/v1/subscriptions/cancel
 */
export const cancelSubscription = async (req: Request, res: Response) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'Missing userId',
      });
    }

    const subscriptionRef = db.collection('subscriptions').doc(userId);
    const subscriptionDoc = await subscriptionRef.get();

    if (!subscriptionDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Subscription not found',
      });
    }

    // Update subscription to cancelled (but keep until end date)
    await subscriptionRef.update({
      autoRenew: false,
      status: 'cancelled',
      cancelledAt: new Date(),
      updatedAt: new Date(),
    });

    console.log(`✅ Subscription cancelled for user ${userId}`);

    return res.status(200).json({
      success: true,
      message: 'Subscription cancelled successfully. Access continues until end date.',
    });
  } catch (error: any) {
    console.error('❌ Cancel subscription error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to cancel subscription',
      error: error.message,
    });
  }
};

/**
 * Get payment history for a user
 * GET /api/v1/subscriptions/history/:userId
 */
export const getPaymentHistory = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const historySnapshot = await db
      .collection('paymentHistory')
      .where('userId', '==', userId)
      .orderBy('paymentDate', 'desc')
      .limit(50)
      .get();

    const history = historySnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      paymentDate: doc.data().paymentDate?.toDate().toISOString(),
      subscriptionStartDate: doc.data().subscriptionStartDate?.toDate().toISOString(),
      subscriptionEndDate: doc.data().subscriptionEndDate?.toDate().toISOString(),
    }));

    return res.status(200).json({
      success: true,
      history,
    });
  } catch (error: any) {
    console.error('❌ Get payment history error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to get payment history',
      error: error.message,
    });
  }
};

/**
 * Check and cleanup expired subscriptions (cron job)
 * POST /api/v1/subscriptions/cleanup
 */
export const cleanupExpiredSubscriptions = async (req: Request, res: Response) => {
  try {
    const now = new Date();

    const expiredSnapshot = await db
      .collection('subscriptions')
      .where('subscriptionEndDate', '<=', now)
      .where('status', '==', 'active')
      .get();

    let count = 0;
    for (const doc of expiredSnapshot.docs) {
      await doc.ref.update({
        status: 'expired',
        updatedAt: now,
      });
      count++;
    }

    console.log(`✅ Cleaned up ${count} expired subscriptions`);

    return res.status(200).json({
      success: true,
      message: `Cleaned up ${count} expired subscriptions`,
      count,
    });
  } catch (error: any) {
    console.error('❌ Cleanup error:', error);
    return res.status(500).json({
      success: false,
      message: 'Cleanup failed',
      error: error.message,
    });
  }
};
