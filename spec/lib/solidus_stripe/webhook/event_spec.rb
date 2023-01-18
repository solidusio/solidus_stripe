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
    context "with a valid event" do
      it "returns an event" do
        payload = JSON.generate(SolidusStripe::WebhookFixtures.charge_succeeded)
        fixture = SolidusStripe::WebhookFixtures.new(payload: payload)

        event = described_class.from_request(
          payload: payload, signature_header: fixture.signature_header, secret: fixture.secret
        )

        expect(event).to be_a(described_class)
      end
    end

    context "when the signature is invalid" do
      it "returns nil" do
        payload = JSON.generate(SolidusStripe::WebhookFixtures.charge_succeeded)
        fixture = SolidusStripe::WebhookFixtures.new(payload: payload)
        signature_header = "t=1,v1=1"

        event = described_class.from_request(
          payload: payload, signature_header: signature_header, secret: fixture.secret
        )

        expect(event).to be(nil)
      end
    end

    context "when the payload is malformed" do
      it "returns nil" do
        payload = "invalid"
        fixture = SolidusStripe::WebhookFixtures.new(payload: payload)

        event = described_class.from_request(
          payload: payload, signature_header: fixture.signature_header, secret: fixture.secret
        )

        expect(event).to be(nil)
      end
    end
  end

  describe "#initialize" do
    let(:charge_suceeded_event) do
      Stripe::Event.construct_from(
        SolidusStripe::WebhookFixtures.charge_succeeded
      )
    end

    it "sets the omnes_event_name from the type field" do
      event = described_class.new(stripe_event: charge_suceeded_event)

      expect(event.omnes_event_name).to be(:"stripe.charge.succeeded")
    end

    it "delegates all other methods to the stripe event" do
      event = described_class.new(stripe_event: charge_suceeded_event)

      expect(event.type).to eq("charge.succeeded")
    end
  end

  describe "#payload" do
    let(:charge_suceeded_event) do
      Stripe::Event.construct_from(
        SolidusStripe::WebhookFixtures.charge_succeeded
      )
    end

    it "returns Hash representation" do
      event = described_class.new(stripe_event: charge_suceeded_event)

      expect(event.payload).to be_a(Hash)
    end

    it "uses strings for the hash keys" do
      event = described_class.new(stripe_event: charge_suceeded_event)

      expect(event.payload.keys).to include("type")
    end
  end
end
