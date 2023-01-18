# frozen_string_literal: true

require "solidus_stripe/webhook/event"
require "stripe"

module SolidusStripe
  class WebhooksController < Spree::BaseController
    SIGNATURE_HEADER = "HTTP_STRIPE_SIGNATURE"

    skip_before_action :verify_authenticity_token, only: :create

    respond_to :json

    def create
      event = Webhook::Event.from_request(payload: request.body.read, signature_header: signature_header)
      return head(:bad_request) unless event

      Spree::Bus.publish(event) && head(:ok)
    end

    private

    def signature_header
      request.headers[SIGNATURE_HEADER]
    end
  end
end
