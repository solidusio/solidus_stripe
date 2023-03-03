# frozen_string_literal: true

SolidusStripe::Engine.routes.draw do
  scope ':payment_method_id' do
    get :payment_confirmation, controller: :intents
    get :setup_confirmation, controller: :intents
  end
  resources :webhooks, only: :create, format: false
end
