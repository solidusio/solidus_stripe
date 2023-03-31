# frozen_string_literal: true

attrs = [:id]
if @current_user_roles.include?("admin")
  attrs += [:stripe_payment_method_id]
end

json.call(payment_source, *attrs)
