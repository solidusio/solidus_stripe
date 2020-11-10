# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Payment Request", type: :request do
  describe "POST /stripe/update_order" do
    it "responds with { success: true } when the order is correctly updated" do
      order = create(:order_ready_to_complete)
      allow_any_instance_of(SolidusStripe::PaymentRequestController).to receive(:current_order).and_return(order)

      with_disabled_forgery_protection do
        post "/stripe/update_order", params: stripe_update_request_params(order: order)
      end

      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy
    end

    context "when phone number is provided as param and already set on the address" do
      it "overrides the address field" do
        order = create(:order_ready_to_complete)
        allow_any_instance_of(SolidusStripe::PaymentRequestController).to receive(:current_order).and_return(order)

        expect {
          with_disabled_forgery_protection do
            post "/stripe/update_order", params: stripe_update_request_params(order: order, shipping_address: default_shipping_address(phone: nil), phone: '911')
          end
        }.to change { order.shipping_address.phone }.to('911')
      end
    end

    context "when phone number is provided both as shipping address param and main param, and already set on the address" do
      it "overrides the address field giving precedence to the shipping address param" do
        order = create(:order_ready_to_complete)
        allow_any_instance_of(SolidusStripe::PaymentRequestController).to receive(:current_order).and_return(order)

        expect {
          with_disabled_forgery_protection do
            post "/stripe/update_order", params: stripe_update_request_params(order: order, shipping_address: default_shipping_address(phone: '555'), phone: '911')
          end
        }.to change { order.shipping_address.phone }.to('555')
      end
    end

    context "when phone number is not required, not provided as param and not set on the shipping address" do
      it "does not populate the address field" do
        with_address_phone_not_required
        order = create(:order_ready_to_complete, shipping_address: create(:address, phone: nil))
        allow_any_instance_of(SolidusStripe::PaymentRequestController).to receive(:current_order).and_return(order)

        expect {
          with_disabled_forgery_protection do
            post "/stripe/update_order", params: stripe_update_request_params(order: order, shipping_address: default_shipping_address(phone: nil), phone: nil)
          end
        }.not_to change { order.shipping_address.phone }
      end
    end

    context "when phone number is not required, provided as param and not set on the shipping address" do
      it "populates the address field with the phone passed as param" do
        with_address_phone_not_required
        order = create(:order_ready_to_complete, shipping_address: create(:address, phone: nil))
        allow_any_instance_of(SolidusStripe::PaymentRequestController).to receive(:current_order).and_return(order)

        expect {
          with_disabled_forgery_protection do
            post "/stripe/update_order", params: stripe_update_request_params(order: order, shipping_address: default_shipping_address(phone: nil), phone: '911')
          end
        }.to change { order.shipping_address.phone }.from(nil).to('911')
      end
    end

    context "when phone number is not required, provided as param but already set on the shipping address" do
      it "populates the address field with the phone passed in the shipping field" do
        with_address_phone_not_required
        order = create(:order_ready_to_complete, shipping_address: create(:address, phone: nil))
        allow_any_instance_of(SolidusStripe::PaymentRequestController).to receive(:current_order).and_return(order)

        expect {
          with_disabled_forgery_protection do
            post "/stripe/update_order", params: stripe_update_request_params(order: order, shipping_address: default_shipping_address(phone: '555'), phone: '911')
          end
        }.to change { order.shipping_address.phone }.from(nil).to('555')
      end
    end
  end

  private

  def with_address_phone_not_required
    if Spree::Config.respond_to?(:address_requires_phone)
      stub_spree_preferences(address_requires_phone: false)
    else
      allow_any_instance_of(Spree::Address).to receive(:require_phone?).and_return(false)
    end
  end

  def with_disabled_forgery_protection
    original_allow_forgery_protection_value = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false

    yield

    ActionController::Base.allow_forgery_protection = original_allow_forgery_protection_value
  end

  def stripe_update_request_params(
    order:,
    shipping_address: nil,
    name: 'Clark Kent',
    phone: '555-555-0199'
    )

    {
      shipping_address: shipping_address || default_shipping_address,
      shipping_option: {
        id: order.shipments.first.shipping_rates.first.shipping_method.id
      },
      name: name,
      phone: phone,
      email: order.email
    }
  end

  def default_shipping_address(
    country: nil,
    region: nil,
    recipient: 'Clark Kent',
    city: 'Metropolis',
    postal_code: '12345',
    address_line: ['12, Lincoln Rd'],
    phone: '555-555-0199'
    )

    if country.blank? || region.blank?
      state = create(:state)

      country ||= state.country.iso
      region ||= state.abbr
    end

    {
      country: country,
      region: region,
      recipient: recipient,
      city: city,
      postalCode: postal_code,
      addressLine: address_line,
      phone: phone
    }
  end
end
