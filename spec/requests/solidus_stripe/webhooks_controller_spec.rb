require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::WebhooksController, type: :request do
  describe "POST /create" do
    let(:signature_header_key) { described_class::SIGNATURE_HEADER }
    let(:fixture) { SolidusStripe::WebhookFixtures.new(payload: payload) }

    before do
      allow(Rails.application.credentials).to receive(:solidus_stripe)
        .and_return({ webhook_endpoint_secret: fixture.secret })
    end

    context "when the request is valid" do
      let(:payload) { JSON.generate(SolidusStripe::WebhookFixtures.charge_succeeded) }

      around do |example|
        if Spree::Bus.registry.registered?(:"stripe.charge.succeeded")
          example.run
        else
          Spree::Bus.register(:"stripe.charge.succeeded")
          example.run
          Spree::Bus.registry.unregister(:"stripe.charge.succeeded")
        end
      end

      it "triggers a matching event on Spree::Bus" do
        event_type = nil
        subscription = Spree::Bus.subscribe(:"stripe.charge.succeeded") { |event| event_type = event.type }

        post "/solidus_stripe/webhooks", params: payload, headers: { signature_header_key => fixture.signature_header }

        expect(event_type).to eq("charge.succeeded")
      ensure
        Spree::Bus.unsubscribe(subscription)
      end

      it "returns a 200 status code" do
        post "/solidus_stripe/webhooks", params: payload, headers: { signature_header_key => fixture.signature_header }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the event can't be generated" do
      let(:payload) { "invalid" }

      it "returns a 400 status code" do
        post "/solidus_stripe/webhooks", params: payload, headers: { signature_header_key => fixture.signature_header }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
