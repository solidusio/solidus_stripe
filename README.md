Solidus Stripe
===============

[![CircleCI](https://circleci.com/gh/solidusio/solidus_stripe.svg?style=svg)](https://circleci.com/gh/solidusio/solidus_stripe)

Stripe Payment Method for Solidus. It works as a wrapper for the ActiveMerchant Stripe gateway.

---

Installation
------------

In your Gemfile:

```ruby
gem 'solidus_stripe', '~> 3.0'
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
to change the `v3_intents` preference from the code above to true.

Also, if you want to allow Apple Pay and Google Pay payments using the
Stripe  payment request button API, you only need to set the `stripe_country`
preference, which represents the two-letter country code of your Stripe
account. Conversely, if you need to disable the button you can simply remove
the `stripe_country` preference.

Please refer to Stripe official
[documentation](https://stripe.com/docs/stripe-js/elements/payment-request-button)
for further instructions on how to make this work properly.

The following configuration will use both Payment Intents and the
payment request button API on the store payment page:


```ruby
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

It's possible to pay with Apple Pay and Google Pay directly from the cart
page. The functionality is self-contained in the view partial
`_stripe_payment_request_button.html.erb`. In order to use it, you need
to load that partial in the `orders#edit` frontend page, and pass it the
payment method configured for Stripe via the local variable
`cart_checkout_payment_method`, for example using `deface`:

```ruby
# app/overrides/spree/orders/edit/add_payment_request_button.html.erb.deface

<!-- insert_after '[data-hook="cart_container"]' -->
<%= render 'stripe_payment_request_button', cart_checkout_payment_method: Spree::PaymentMethod::StripeCreditCard.first %>
```

Of course, the rules listed in the Payment Intents section (adding the stripe
country config value, for example) apply also for this feature.

Customizing the V3 API javascript
---------------------------------

Stripe V3 JS code is now managed via Sprockets. If you need to customize the JS,
you can simply override or/and add new methods to the relevant object prototype.
Make sure you load your customizations after Stripe initalization code from
`spree/frontend/solidus_stripe`.

For example, the following code adds a callback method in order to print a debug
message on the console:

```js
SolidusStripe.CartPageCheckout.prototype.onPrButtonMounted = function(id, result) {
  if (result) {
    $('#' + id).parent().show();
    console.log('Payment request button is now mounted on element with id #' + id);
  } else {
    console.log('Payment request button failed initalization.');
  }
}
```

Custom Stripe Elements options
-----------------------

Some custom options, like locale and fonts, can be passed when [creating a Stripe Elements instance](https://stripe.com/docs/js/elements_object/create). To customize the default options this gem provides, override the `SolidusStripe.Payment.prototype.elementsBaseOptions` method.


Styling Stripe Elements
-----------------------

The Elements feature built in this gem come with some standard styles. If you want
to customize it, you can override the `SolidusStripe.Elements.prototype.baseStyle`
method and make it return a valid [Stripe Style](https://stripe.com/docs/js/appendix/style)
object:

```js
SolidusStripe.Elements.prototype.baseStyle = function () {
  return {
    base: {
      iconColor: '#c4f0ff',
      color: '#fff',
      fontWeight: 500,
      fontFamily: 'Roboto, Open Sans, Segoe UI, sans-serif',
      fontSize: '16px',
      fontSmoothing: 'antialiased',
      ':-webkit-autofill': {
        color: '#fce883',
      },
      '::placeholder': {
        color: '#87BBFD',
      },
    },
    invalid: {
      iconColor: '#FFC7EE',
      color: '#FFC7EE',
    }
  }
};
```

You can also style your element containers directly by using CSS rules like this:

```css
  .StripeElement {
    border: 1px solid transparent;
  }

  .StripeElement--focus {
    box-shadow: 0 1px 3px 0 #cfd7df;
  }

  .StripeElement--invalid {
    border-color: #fa755a;
  }

  .StripeElement--webkit-autofill {
    background-color: #fefde5 !important;
  }
```

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
