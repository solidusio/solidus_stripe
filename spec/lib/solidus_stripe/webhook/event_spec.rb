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
        data: SolidusStripe::Webhook::DataFixtures.charge_succeeded
      )
    end

    context "with a valid event" do
      it "returns an event" do
        event = described_class.from_request(
          payload: context.json, signature_header: context.signature_header, secret: context.secret
        )

        expect(event).to be_a(described_class)
      end
    end

    context "when the signature is invalid" do
      it "returns nil" do
        signature_header = "t=1,v1=1"

        event = described_class.from_request(
          payload: context.json, signature_header: signature_header, secret: context.secret
        )

        expect(event).to be(nil)
      end
    end

    context "when the tolerance has expired" do
      it "returns nil" do
        event = described_class.from_request(
          payload: context.json, signature_header: context.signature_header, secret: context.secret, tolerance: 0
        )

        expect(event).to be(nil)
      end
    end

    context "when the payload is malformed" do
      it "returns nil" do
        event = described_class.from_request(
          payload: "invalid", signature_header: context.signature_header, secret: context.secret
        )

        expect(event).to be(nil)
      end
    end
  end

  describe "#initialize" do
    let(:stripe_event) do
      SolidusStripe::Webhook::EventWithContextFactory.new(
        data: SolidusStripe::Webhook::DataFixtures.charge_succeeded
      ).stripe_object
    end

    it "sets the omnes_event_name from the type field" do
      event = described_class.new(stripe_event: stripe_event)

      expect(event.omnes_event_name).to be(:"stripe.charge.succeeded")
    end

    it "delegates all other methods to the stripe event" do
      event = described_class.new(stripe_event: stripe_event)

      expect(event.type).to eq("charge.succeeded")
    end
  end

  describe "#payload" do
    let(:stripe_event) do
      SolidusStripe::Webhook::EventWithContextFactory.new(
        data: SolidusStripe::Webhook::DataFixtures.charge_succeeded
      ).stripe_object
    end

    it "returns Hash representation" do
      event = described_class.new(stripe_event: stripe_event)

      expect(event.payload).to be_a(Hash)
    end

    it "uses strings for the hash keys" do
      event = described_class.new(stripe_event: stripe_event)

      expect(event.payload.keys).to include("type")
    end
  end
end
