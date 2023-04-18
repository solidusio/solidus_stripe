require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::WebhooksController, type: [:request, :webhook_request] do
  describe "POST /create" do
    let(:payment_method) { create(:solidus_stripe_payment_method) }
    let(:payment_intent) {
      payment_method.gateway.request {
        Stripe::PaymentIntent.create(amount: 100, currency: 'usd')
      }
    }
    let(:context) do
      SolidusStripe::Webhook::EventWithContextFactory.from_object(
        object: payment_intent,
        type: "payment_intent.created",
        payment_method: payment_method
      )
    end

    context "when the request is valid" do
      around do |example|
        if Spree::Bus.registry.registered?(:"stripe.payment_intent.created")
          example.run
        else
          Spree::Bus.register(:"stripe.payment_intent.created")
          example.run
          Spree::Bus.registry.unregister(:"stripe.payment_intent.created")
        end
      end

      it "triggers a matching event on Spree::Bus" do
        event_type = nil
        subscription = Spree::Bus.subscribe(:"stripe.payment_intent.created") { |event| event_type = event.type }

        webhook_request(context)

        expect(event_type).to eq("payment_intent.created")
      ensure
        Spree::Bus.unsubscribe(subscription)
      end

      it "returns a 200 status code" do
        webhook_request(context)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the event can't be generated" do
      it "returns a 400 status code" do
        webhook_request(context, timestamp: Time.zone.yesterday.to_time)

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
