Spree::Core::Engine.routes.draw do
  post '/stripe/confirm_payment', to: 'stripe#confirm_payment'
end
