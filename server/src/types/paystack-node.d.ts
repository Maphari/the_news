declare module 'paystack-node' {
  interface PaystackTransactionVerifyResponse {
    status: boolean;
    message: string;
    data: {
      id: number;
      domain: string;
      status: string;
      reference: string;
      amount: number;
      message: string | null;
      gateway_response: string;
      paid_at: string;
      created_at: string;
      channel: string;
      currency: string;
      ip_address: string;
      metadata: Record<string, any>;
      log: any;
      fees: number;
      fees_split: any;
      authorization: any;
      customer: any;
      plan: any;
      split: any;
      order_id: any;
      paidAt: string;
      createdAt: string;
      requested_amount: number;
      pos_transaction_data: any;
    };
  }

  interface PaystackTransactionInitializeResponse {
    status: boolean;
    message: string;
    data: {
      authorization_url: string;
      access_code: string;
      reference: string;
    };
  }

  interface PaystackTransaction {
    verify(params: { reference: string }): Promise<PaystackTransactionVerifyResponse>;
    initialize(params: any): Promise<PaystackTransactionInitializeResponse>;
  }

  class Paystack {
    constructor(secretKey: string);
    transactions: PaystackTransaction;
    transaction?: PaystackTransaction;
  }

  export = Paystack;
}
