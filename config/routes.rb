# frozen_string_literal: true

SolidusStripe::Engine.routes.draw do
  resources :payment_intents, only: :create
end
