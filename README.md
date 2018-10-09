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

Testing
-------

Then just run the following to automatically build a dummy app if necessary and
run the tests:

```shell
bundle exec rake
```
