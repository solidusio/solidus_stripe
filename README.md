Solidus Stripe
===============

[![CircleCI](https://circleci.com/gh/solidusio/solidus_stripe.svg?style=svg)](https://circleci.com/gh/solidusio/solidus_stripe)

Stripe Payment Method for Solidus. It works as a wrapper for the ActiveMerchant Stripe gateway.

---

Installation
------------

In your Gemfile:

```ruby
gem 'solidus_stripe', '~> 1.0.0'
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
    stripe_country: 'US',
    v3_elements: false,
    v3_intents: false,
    server: Rails.env.production? ? 'production' : 'test',
    test_mode: !Rails.env.production?
  )
end
```

Once your server has been restarted, you can select in the Preference
Source field a new entry called `stripe_env_credentials`. After saving,
your  application will start using the static configuration to process
Stripe payments.


Using Stripe Payment Intents API
--------------------------------

If you want to use the new SCA-ready Stripe Payment Intents API you need
to change the `v3_intents` preference from the code above to true and,
if you want to allow also Apple Pay and Google Pay payments, set the
`stripe_country` preference, which represents the two-letter country
code of your Stripe account:


```
Spree.config do |config|
  # ...

  config.static_model_preferences.add(
    Spree::PaymentMethod::StripeCreditCard,
    'stripe_env_credentials',
    secret_key: ENV['STRIPE_SECRET_KEY'],
    publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
    stripe_country: 'US',
    v3_elements: false,
    v3_intents: true,
    server: Rails.env.production? ? 'production' : 'test',
    test_mode: !Rails.env.production?
  )
end
```

Apple Pay and Google Pay
-----------------------

The Payment Intents API now supports also Apple Pay and Google Pay via
the [payment request button API](https://stripe.com/docs/stripe-js/elements/payment-request-button).
Check the Payment Intents section for setup details. Also, please
refer to the official Stripe documentation for configuring your
Stripe account to receive payments via Apple Pay.


Migrating from solidus_gateway
------------------------------

If you were previously using `solidus_gateway` gem you might want to
check out our [Wiki page](https://github.com/solidusio/solidus_stripe/wiki/Migrating-from-solidus_gateway)
that describes how to handle this migration.

Testing
-------

Then just run the following to automatically build a dummy app if necessary and
run the tests:

```shell
bundle exec rake
```

Releasing
---------

We use [gem-release](https://github.com/svenfuchs/gem-release) to release this
extension with ease.

Supposing you are on the master branch and you are working on a fork of this
extension, `upstream` is the main remote and you have write access to it, you
can simply run:

```
gem bump --version minor --tag --release --remote upstream
```

This command will:

- bump the gem version to the next minor (changing the `version.rb` file)
- commit the change and push it to upstream master
- create a git tag
- push the tag to the upstream remote
- release the new version on RubyGems

Or you can run these commands individually:

```
gem bump --version minor --remote upstream
gem tag --remote upstream
gem release
```
