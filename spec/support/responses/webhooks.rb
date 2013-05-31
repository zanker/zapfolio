module Responses
  STRIPE = HashWithIndifferentAccess.new({
    # CUSTOMER.SUBSCRIPTION.CREATED
    "customer.subscription.created" => {
      "object" => "event",
      "type" => "customer.subscription.created",
      "webhooks" => [],
      "livemode" => false,
      "created" => 1339392077,
      "pending_webhooks" => 0,
      "id" => "evt_AsAb6K5TPO8zFo",
      "data" => {
        "object" => {
          "customer" => "cus_aA1mvC5xCILOB0",
          "cancel_at_period_end" => false,
          "current_period_end" => 1341984077,
          "trial_start" => 1339392077,
          "current_period_start" => 1339392077,
          "ended_at" => nil,
          "start" => 1339392077,
          "status" => "trialing",
          "trial_end" => 1341984077,
          "canceled_at" => nil,
          "plan" => {
            "currency" => "usd",
            "livemode" => false,
            "id" => "starter",
            "interval" => "month",
            "name" => "Starter",
            "amount" => 500,
            "trial_period_days" => 30,
            "object" => "plan"
          },
          "object" => "subscription"
        }
      }
    },

    # CUSTOMER.SUBSCRIPTION.UPDATED
    "customer.subscription.updated" => {
      "object" => "event",
      "type" => "customer.subscription.updated",
      "webhooks" => [],
      "livemode" => false,
      "created" => 1339392078,
      "pending_webhooks" => 0,
      "id" => "evt_WPXQxweo8MX3Mf",
      "data" => {
        "object" => {
          "customer" => "cus_aA1mvC5xCILOB0",
          "cancel_at_period_end" => true,
          "current_period_end" => 1341984077,
          "trial_start" => 1339392077,
          "current_period_start" => 1339392077,
          "ended_at" => 1339392078,
          "start" => 1339392077,
          "status" => "trialing",
          "canceled_at" => 1339392078,
          "plan" => {
            "currency" => "usd",
            "id" => "starter",
            "livemode" => false,
            "interval" => "month",
            "amount" => 500,
            "name" => "Starter",
            "trial_period_days" => 30,
            "object" => "plan"
          },
          "trial_end" => 1341984077,
          "object" => "subscription"
        },
        "previous_attributes" => {
          "cancel_at_period_end" => false,
          "ended_at" => nil,
          "canceled_at" => nil
        }
      }
    },

    # CUSTOMER.SUBSCRIPTION.DELETED
    "customer.subscription.deleted" => {
      "object" => "event",
      "type" => "customer.subscription.deleted",
      "webhooks" => [],
      "livemode" => false,
      "created" => 1339556643,
      "pending_webhooks" => 0,
      "id" => "evt_xo0Q8njcZU0iLk",
      "data" => {
        "object" => {
          "customer" => "cus_aA1mvC5xCILOB0",
          "cancel_at_period_end" => false,
          "current_period_end" => 1341983518,
          "trial_start" => 1339391518,
          "current_period_start" => 1339391518,
          "ended_at" => 1339556643,
          "start" => 1339391697,
          "status" => "canceled",
          "canceled_at" => 1339556643,
          "plan" => {
            "currency" => "usd",
            "id" => "premium",
            "livemode" => false,
            "interval" => "month",
            "amount" => 1500,
            "name" => "Premium",
            "trial_period_days" => 30,
            "object" => "plan"
          },
          "trial_end" => 1341983518,
          "object" => "subscription"
        }
      }
    },

    # CUSTOMER.SUBSCRIPTION.TRIAL_WILL_END
    "customer.subscription.trial_will_end" => {
      "object" => "event",
      "type" => "customer.subscription.trial_will_end",
      "webhooks" => [],
      "livemode" => false,
      "created" => 1339557097,
      "pending_webhooks" => 0,
      "id" => "evt_u9TIzQUESA9RrZ",
      "data" => {
        "object" => {
          "customer" => "cus_aA1mvC5xCILOB0",
          "cancel_at_period_end" => false,
          "current_period_end" => 1339557291,
          "trial_start" => 1339392070,
          "current_period_start" => 1339392070,
          "start" => 1339556992,
          "ended_at" => nil,
          "status" => "trialing",
          "plan" => {
            "currency" => "usd",
            "id" => "premium",
            "livemode" => false,
            "interval" => "month",
            "name" => "Premium",
            "amount" => 1500,
            "trial_period_days" => 30,
            "object" => "plan"
          },
          "trial_end" => 1339557291,
          "canceled_at" => nil,
          "object" => "subscription"
        }
      }
    },

    # INVOICE.PAYMENT_SUCCEEDED
    "invoice.payment_succeeded" => {
      "object" => "event",
      "type" => "invoice.payment_succeeded",
      "webhooks" => [],
      "livemode" => false,
      "created" => 1339392077,
      "pending_webhooks" => 0,
      "id" => "evt_C5i1aFuexAm9X1",
      "data" => {
        "object" => {
          "subtotal" => 1500,
          "discount" => nil,
          "customer" => "cus_aA1mvC5xCILOB0",
          "livemode" => false,
          "id" => "in_wqFfYE5bxIVJp0",
          "period_end" => 1339392077,
          "total" => 1500,
          "charge" => nil,
          "lines" => {
            "prorations" => [],
            "invoiceitems" => [],
            "subscriptions" => [{
              "plan" => {
                "object" => "plan",
                "currency" => "usd",
                "interval" => "month",
                "amount" => 500,
                "name" => "Starter",
                "livemode" => false,
                "id" => "starter",
                "trial_period_days" => 30
              },
              "amount" => 0,
              "period" => {
                "end" => 1341984077,
                "start" => 1339392077
              }
            }]
          },
          "paid" => true,
          "attempt_count" => 0,
          "amount_due" => 0,
          "attempted" => true,
          "next_payment_attempt" => nil,
          "object" => "invoice",
          "closed" => true,
          "period_start" => 1339392077,
          "date" => 1339392077,
          "ending_balance" => nil,
          "starting_balance" => 0
        }
      }
    },

    # INVOICE.PAYMENT_FAILED
    "invoice.payment_failed" => {
      "id" => "evt_Ar1o341341oixaf",
      "livemode" => false,
      "type" => "invoice.payment_failed",
      "created" => 1326853478,
      "data" => {
        "object" => {
          "attempted" => true,
          "charge" => "ch_00000000000000",
          "closed" => true,
          "customer" => "cus_aA1mvC5xCILOB0",
          "date" => 1327101120,
          "id" => "in_00000000000000",
          "lines" => {
            "subscriptions" => [
              {
                "amount" => 1500,
                "period" => {
                  "end" => 1329779520,
                  "start" => 1327101120
                },
                "plan" => {
                  "amount" => 1500,
                  "currency" => "usd",
                  "id" => "premium",
                  "interval" => "month",
                  "livemode" => false,
                  "name" => "Premium",
                  "object" => "plan"
                }
              }
            ]
          },
          "livemode" => false,
          "object" => "invoice",
          "paid" => false,
          "period_end" => 1327101120,
          "period_start" => 1327101120,
          "subtotal" => 999,
          "total" => 999
        }
      },
    }
  })
end