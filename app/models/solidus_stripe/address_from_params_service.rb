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
        Spree::Address.new(attributes)
      end
    end

    private

    def attributes
      @attributes ||= begin
        default_attributes.tap do |attributes|
          # possibly anonymized attributes:
          phone = address_params[:phone]
          lines = address_params[:addressLine]
          names = address_params[:recipient].split(' ')

          name_attributes = if SolidusSupport.combined_first_and_last_name_in_address? && Spree::Address.column_names.include?("name")
            {
              name: address_params[:recipient]
            }
          else
            {
              firstname: names.first,
              lastname: names.last,
            }
          end

          attributes
            .merge!(name_attributes)
            .merge!(
              state_id: state&.id,
              phone: phone,
              address1: lines.first,
              address2: lines.second
            )
            .reject! { |_, value| value.blank? }
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
