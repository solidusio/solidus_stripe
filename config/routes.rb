Spree::Core::Engine.routes.draw do
  post '/stripe/confirm_payment', to: 'stripe#confirm_payment'

  # payment request routes:
  post '/stripe/shipping_rates', to: '/solidus_stripe/payment_request#shipping_rates'
  post '/stripe/update_order', to: '/solidus_stripe/payment_request#update_order'
end
