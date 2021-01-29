# frozen_string_literal: true

# Since https://github.com/solidusio/solidus/pull/3524 was merged,
# we need to verify if we're using the single "Name" field or the
# previous first/last name combination.
module SolidusAddressNameHelper
  def fill_in_name
    if has_field?("First Name")
      fill_in "First Name", with: "Han"
      fill_in "Last Name", with: "Solo"
    else
      fill_in "Name", with: "Han Solo"
    end
  end
end
