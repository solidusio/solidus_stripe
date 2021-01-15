# frozen_string_literal: true

module SolidusCardInputHelper
  def fill_in_card(card = {})
    card[:number] ||= "4242 4242 4242 4242"
    card[:code] ||= "123"
    card[:exp_month] ||= "01"
    card[:exp_year] ||= "#{Time.zone.now.year + 1}"

    if preferred_v3_elements || preferred_v3_intents
      within_frame find('#card_number iframe') do
        fill_in_number("cardnumber", card)
      end
      within_frame(find '#card_cvc iframe') { fill_in 'cvc', with: card[:code] }
      within_frame(find '#card_expiry iframe') do
        fill_in_expiration("exp-date", card)
      end
    else
      fill_in_number("Card Number", card)
      fill_in "Card Code", with: card[:code]
      fill_in_expiration("Expiration", card)
    end
  end

  private

  def fill_in_number(field_name, card)
    card[:number].split('').each { |n| find_field(field_name).native.send_keys(n) }
  end

  def fill_in_expiration(field_name, card)
    "#{card[:exp_month]}#{card[:exp_year].last(2)}".split('').each { |n| find_field(field_name).native.send_keys(n) }
  end
end
