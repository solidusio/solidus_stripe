Stripe.api_key = Spree::PaymentMethod::StripeCreditCard.last&.preferences&.dig(:secret_key)
