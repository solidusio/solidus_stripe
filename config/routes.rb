# frozen_string_literal: true

SolidusStripe::Engine.routes.draw do
  scope ':slug' do
    get :after_confirmation, to: 'intents#after_confirmation'
    post :webhooks, to: 'webhooks#create', format: false
  end
end

Spree::Core::Engine.routes.draw do
  namespace :solidus_stripe, defaults: { format: 'json' } do
    namespace :api do
      post :create_setup_intent, to: 'intents#create_setup_intent'
      post :create_payment_intent, to: 'intents#create_payment_intent'
    end
  end
end
