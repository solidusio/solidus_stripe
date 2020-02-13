# frozen_string_literal: true

module SolidusStripe
  class ShippingRatesService
    attr_reader :order, :user, :shipping_address_params

    def initialize(order, user, shipping_address_params)
      @order = order
      @user = user
      @shipping_address_params = shipping_address_params
    end

    def call
      # setting a temporary and probably incomplete address to the order
      # only to calculate the available shipping options:
      order.ship_address = address_from_params

      available_shipping_methods.each_with_object([]) do |(id, rates), options|
        options << shipping_method_data(id, rates)
      end
    end

    private

    def available_shipping_methods
      shipments = Spree::Stock::SimpleCoordinator.new(order).shipments
      all_rates = shipments.map(&:shipping_rates).flatten

      all_rates.group_by(&:shipping_method_id).select do |_, rates|
        rates.size == shipments.size
      end
    end

    def shipping_method_data(id, rates)
      {
        id: id.to_s,
        label: Spree::ShippingMethod.find(id).name,
        amount: (rates.sum(&:cost) * 100).to_i
      }
    end

    def address_from_params
      SolidusStripe::AddressFromParamsService.new(shipping_address_params, user).call
    end
  end
end
