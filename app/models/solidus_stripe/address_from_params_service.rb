# frozen_string_literal: true

module SolidusStripe
  class AddressFromParamsService
    attr_reader :address_params, :user

    def initialize(address_params, user = nil)
      @address_params, @user = address_params, user
    end

    def call
      if user
        user.addresses.find_or_initialize_by(attributes)
      else
        begin
          Spree::Address.new(attributes)
        rescue ActiveModel::UnknownAttributeError # Handle old address format
          name = attributes.delete!(:name)
          attributes[:first_name], attributes[:last_name] = name.split(/[[:space:]]/, 2)
          Spree::Address.new(attributes)
        end
      end
    end

    private

    def attributes
      @attributes ||= begin
        default_attributes.tap do |attributes|
          # possibly anonymized attributes:
          phone = address_params[:phone]
          lines = address_params[:addressLine]
          name = address_params[:recipient]

          attributes.merge!(
            state_id: state&.id,
            name: name,
            phone: phone,
            address1: lines.first,
            address2: lines.second
          ).reject! { |_, value| value.blank? }
        end
      end
    end

    def country
      @country ||= Spree::Country.find_by_iso(address_params[:country])
    end

    def state
      @state ||= begin
        region = address_params[:region]
        country.states.find_by(abbr: region) || country.states.find_by(name: region)
      end
    end

    def default_attributes
      {
        country_id: country.id,
        city: address_params[:city],
        zipcode: address_params[:postalCode]
      }
    end
  end
end
