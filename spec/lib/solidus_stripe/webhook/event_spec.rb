# frozen_string_literal: true

require "solidus_stripe_spec_helper"
require "solidus_stripe/webhook/event"
require "omnes/bus"

RSpec.describe SolidusStripe::Webhook::Event do
  describe ".register" do
    it "registers core events prepending with 'stripe'" do
      bus = Omnes::Bus.new

      described_class.register(bus: bus, core_events: %i[foo], user_events: [])

      expect(bus.registry.registered?(:"stripe.foo")).to be(true)
    end

    it "registers user events prepending with 'stripe'" do
      bus = Omnes::Bus.new

      described_class.register(bus: bus, user_events: %i[foo])

      expect(bus.registry.registered?(:"stripe.foo")).to be(true)
    end
  end

  describe ".from_request" do
    let(:context) do
      SolidusStripe::Webhook::EventWithContextFactory.from_data(
        data: SolidusStripe::Webhook::DataFixtures.charge_succeeded,
        payment_method: create(:stripe_payment_method)
      )
    end

    context "with a valid event" do
      it "returns an event" do
        event = described_class.from_request(
          payload: context.json, signature_header: context.signature_header, slug: context.slug
        )

        expect(event).to be_a(described_class)
      end
    end

    context "when the signature is invalid" do
      it "returns nil" do
        signature_header = "t=1,v1=1"

        event = described_class.from_request(
          payload: context.json, signature_header: signature_header, slug: context.slug
        )

        expect(event).to be(nil)
      end
    end

    context "when the tolerance has expired" do
      it "returns nil" do
        event = described_class.from_request(
          payload: context.json, signature_header: context.signature_header, tolerance: 0, slug: context.slug
        )

        expect(event).to be(nil)
      end
    end

    context "when the payload is malformed" do
      it "returns nil" do
        event = described_class.from_request(
          payload: "invalid", signature_header: context.signature_header, slug: context.slug
        )

        expect(event).to be(nil)
      end
    end

    context "when the slug is not known" do
      it "returns nil" do
        event = described_class.from_request(
          payload: context.json, signature_header: context.signature_header, slug: "foo"
        )

        expect(event).to be(nil)
      end
    end
  end

  describe "#initialize" do
    let(:context) do
      SolidusStripe::Webhook::EventWithContextFactory.new(
        data: SolidusStripe::Webhook::DataFixtures.charge_succeeded,
        payment_method: create(:stripe_payment_method)
      )
    end

    it "sets the payment method" do
      event = described_class.new(stripe_event: context.stripe_object, payment_method: context.payment_method)

      expect(event.payment_method).to be(context.payment_method)
    end

    it "sets the omnes_event_name from the event type field" do
      event = described_class.new(stripe_event: context.stripe_object, payment_method: context.payment_method)

      expect(event.omnes_event_name).to be(:"stripe.charge.succeeded")
    end

    it "delegates all other methods to the stripe event" do
      event = described_class.new(stripe_event: context.stripe_object, payment_method: context.payment_method)

      expect(event.type).to eq("charge.succeeded")
    end
  end

  describe "#payload" do
    let(:context) do
      SolidusStripe::Webhook::EventWithContextFactory.new(
        data: SolidusStripe::Webhook::DataFixtures.charge_succeeded,
        payment_method: create(:stripe_payment_method)
      )
    end

    it "includes stripe event Hash representation" do
      event = described_class.new(stripe_event: context.stripe_object, payment_method: context.payment_method)

      expect(event.payload["stripe_event"]).to eq(context.stripe_object.as_json)
    end

    it "includes spree payment method id" do
      event = described_class.new(stripe_event: context.stripe_object, payment_method: context.payment_method)

      expect(event.payload["payment_method_id"]).to be(context.payment_method.id)
    end
  end
end
