# frozen_string_literal: true

module SolidusStripe::LogEntries
  extend ActiveSupport::Concern
  extend self

  # Builds an ActiveMerchant::Billing::Response
  #
  # @option [true,false] :success
  # @option [String] :message
  # @option [String] :response_code
  # @option [#to_json] :data
  #
  # @return [return type] return description
  def build_payment_log(success:, message:, response_code: nil, data: nil)
    ActiveMerchant::Billing::Response.new(
      success,
      message,
      { 'data' => data.to_json },
      { authorization: response_code },
    )
  end

  def payment_log(payment, **options)
    payment.log_entries.create!(details: YAML.safe_dump(
      build_payment_log(**options),
      permitted_classes: Spree::LogEntry.permitted_classes,
      aliases: Spree::Config.log_entry_allow_aliases,
    ))
  end
end
