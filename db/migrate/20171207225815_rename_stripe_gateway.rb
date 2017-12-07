class RenameStripeGateway < SolidusSupport::Migration[4.2]
  def up
    Spree::PaymentMethod.where(type: 'Spree::Gateway::StripeGateway').
      update_all(type: 'Spree::PaymentMethod::Stripe')
  end

  def down
    Spree::PaymentMethod.where(type: 'Spree::PaymentMethod::Stripe').
      update_all(type: 'Spree::Gateway::StripeGateway')
  end
end
