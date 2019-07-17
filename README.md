Solidus Stripe
===============

[![CircleCI](https://circleci.com/gh/solidusio-contrib/solidus_stripe.svg?style=svg)](https://circleci.com/gh/solidusio-contrib/solidus_stripe)

Stripe Payment Method for Solidus. It works as a wrapper for the ActiveMerchant Stripe gateway.

---

Installation
------------

In your Gemfile:

```ruby
gem "solidus_stripe", github: "solidusio-contrib/solidus_stripe"
```

Then run from the command line:

```shell
bundle install
bundle exec rails g solidus_stripe:install
bundle exec rails db:migrate
```

Usage
-----

Navigate to *Settings > Payments > Payment Methods* in the admin panel.
You can now create a new payment method that uses Stripe by selecting
`Stripe credit card` under Type in the New Payment Method form and saving.
The Stripe payment method's extra fields will be now shown in the form.

**Configure via database configuration**

If you want to store your Stripe credentials in the database just
fill the new fields in the form, selecting `custom` (default) in the
Preference Source field.

**Configure via static configuration**

If you want to store your credentials into your codebase or use ENV
variables you can create the following static configuration:

```ruby
# config/initializers/spree.rb

Spree.config do |config|
  # ...

  config.static_model_preferences.add(
    Spree::PaymentMethod::StripeCreditCard,
    'stripe_env_credentials',
    secret_key: ENV['STRIPE_SECRET_KEY'],
    publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
    v3_elements: false,
    server: Rails.env.production? ? 'production' : 'test',
    test_mode: !Rails.env.production?
  )
end
```

Once your server has been restarted, you can select in the Preference
Source field a new entry called `stripe_env_credentials`. After saving,
your  application will start using the static configuration to process
Stripe payments.


Migrating from solidus_gateway
------------------------------

If you were previously using `solidus_gateway` gem you might want to
check out our [Wiki page](https://github.com/solidusio-contrib/solidus_stripe/wiki/Migrating-from-solidus_gateway)
that describes how to handle this migration.

Testing
-------

Then just run the following to automatically build a dummy app if necessary and
run the tests:

```shell
bundle exec rake
```
