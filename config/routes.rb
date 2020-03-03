Spree::Core::Engine.routes.draw do
  # route to a deprecated controller, will be removed in the future:
  post '/stripe/confirm_payment', to: 'stripe#confirm_payment'

  # payment intents routes:
  post '/stripe/confirm_intents', to: '/solidus_stripe/intents#confirm'

  # payment request routes:
  post '/stripe/shipping_rates', to: '/solidus_stripe/payment_request#shipping_rates'
  post '/stripe/update_order', to: '/solidus_stripe/payment_request#update_order'
end
