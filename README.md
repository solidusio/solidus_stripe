Solidus Stripe
===============

[![Build Status](https://travis-ci.org/solidusio-contrib/solidus_stripe.svg?branch=master)](https://travis-ci.org/solidusio-contrib/solidus_stripe)

Stripe Payment Method for Solidus. It works as a wrapper for the ActiveMerchant Stripe gateway.

---

Installation
------------

In your Gemfile:

```ruby
gem "solidus_stripe"
```

Then run from the command line:

```shell
bundle install
rails g solidus_stripe:install
```

Finally, make sure to **restart your app**. Navigate to *Settings >
Payments > Payment Methods* in the admin panel.  You should see a number of payment
methods and the assigned provider for each.  Click on the payment method you wish
to change the provider, and you should see a number of options under the provider dropdown.

Migrating from solidus_gateway
------------------------------

If you were previously using `solidus_gateway` gem you could need some manual
steps to have this new gem working.

It's important to know that both gems can live together and there
is no need to remove `solidus_gateway` when installing this gem.

Migration steps are:

- Install `solidus_stripe` as described above.
- Run migrations: [this one one](https://github.com/solidusio-contrib/solidus_stripe/blob/ad591678243b805935b2ad03a4006024f890dd33/db/migrate/20181010123508_update_stripe_payment_method_type_to_credit_card.rb)
  is reponsible to update all existing payment methods to use the new Stripe
  payment method type and stop referincing to the `spree_gateway` one. Also, it
  updates the preferences for stripe to point to the new method if they were set
  via legacy database configuration storage.
- Change static model preferences to use `Spree::Gateway::StripeGateway`
  payment method: this is needed only if you use static model preferences. You
  should have this code somewhere in your app (usually) into an initializer:

  ```ruby
  Spree::Config.configure do |config|
    config.static_model_preferences.add(
      Spree::Gateway::StripeGateway,
      'stripe_credentials',
      secret_key: secret_key,
      publishable_key: publishable_key
    )
  end
  ```

  This needs to be changed to:

  ```ruby
  Spree::Config.configure do |config|
    config.static_model_preferences.add(
      Spree::PaymentMethod::StripeCreditCard,
      'stripe_credentials',
      secret_key: secret_key,
      publishable_key: publishable_key
    )
  end
  ```

  Once changes are deployed, check the admin payment method page to be sure
  it's using the right static configuration.

Testing
-------

Then just run the following to automatically build a dummy app if necessary and
run the tests:

```shell
bundle exec rake
```
