# frozen_string_literal: true

module Spree
  module RefundDecorator
    attr_reader :response

    ::Spree::Refund.prepend(self)
  end
end
