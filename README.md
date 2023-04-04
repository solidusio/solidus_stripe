## 🚧 **WARNING** 🚧 Work In Progress

You're looking at the source for `solidus_stripe` v5, which will only support the **starter frontend**
but at the moment **it is not ready to be used**.

Please use [`solidus_stripe` v4 on the corresponding branch](https://github.com/solidusio/solidus_stripe/tree/v4).

## 🚧 **WARNING** 🚧 Supporting `solidus_frontend`

If you need support for `solidus_frontend` please add `< 5` as a version requirement in your gemfile:
`gem 'solidus_stripe', '< 5'`
or if your tracking the github version please switch to the `v4` branch:
`gem 'solidus_stripe', git: 'https://github.com/solidusio/solidus_stripe.git', branch: 'v4'`

---

# Solidus Stripe

[![CircleCI](https://circleci.com/gh/solidusio/solidus_stripe.svg?style=shield)](https://circleci.com/gh/solidusio/solidus_stripe)
[![codecov](https://codecov.io/gh/solidusio/solidus_stripe/branch/master/graph/badge.svg)](https://codecov.io/gh/solidusio/solidus_stripe)

<!-- Explain what your extension does. -->

## Installation

Add solidus_stripe to your Gemfile:

```ruby
gem 'solidus_stripe'
```

Bundle your dependencies and run the installation generator:

```shell
bin/rails generate solidus_stripe:install
```

### Webhooks

This library makes use of some [Stripe webhooks](https://stripe.com/docs/webhooks).

Every Solidus Stripe payment method you create will get a slug assigned. You
need to append it to a generic webhook endpoint to get the URL for that payment
method. For example:

```ruby
SolidusStripe::PaymentMethod.last.slug
# "365a8435cd11300e87de864c149516e0"
```

For the above example, and if you mounted the `SolidusStripe::Engine` routes on
the default scope, the webhook endpoint would look like:

```
/solidus_stripe/webhooks/365a8435cd11300e87de864c149516e0
```

Besides, you also need to configure the webhook signing secret for that payment
method. You can do that through the `webhook_endpoint_signing_secret`
preference on the payment method.

Before going to production, you'll need to [register the webhook endpoint with
Stripe](https://stripe.com/docs/webhooks/go-live), and make sure to subscribe
to the events listed in [the `SolidusStripe::Webhook::Event::CORE`
constant](https://github.com/solidusio/solidus_stripe/blob/master/lib/solidus_stripe/webhook/event.rb).

On development, you can
[test webhooks by using Stripe CLI](https://stripe.com/docs/webhooks/test).

## Usage

### Showing reusable sources in the checkout

When saving stripe payment methods for future usage the checkout requires
a partial for each supported payment method type.

For the full list of types see: https://stripe.com/docs/api/payment_methods/object#payment_method_object-type.

The extension will only install a partial for the `card` type, located in `app/views/checkouts/existing_payment/stripe/_card.html.erb`,
and fall back to a `default` partial otherwise (see `app/views/checkouts/existing_payment/stripe/_default.html.erb`).

As an example, in order to show a wallet source connected to a
[SEPA Debit payment method](https://stripe.com/docs/api/payment_methods/object#payment_method_object-sepa_debit)
the following partial should be added:

`app/views/checkouts/existing_payment/stripe/_sepa_debit.html.erb`

```erb
<% sepa_debit = stripe_payment_method.sepa_debit %>
🏦 <%= sepa_debit.bank_code %> / <%= sepa_debit.branch_code %><br>
IBAN: **** **** **** **** **** <%= sepa_debit.last4 %>
```

### Custom webhooks

You can also use [Stripe webhooks](https://stripe.com/docs/webhooks) to trigger
custom actions in your application.

First, you need to register the event you want to listen to, both [in
Stripe](https://stripe.com/docs/webhooks/go-live) and in your application:

```ruby
# config/initializers/solidus_stripe.rb
SolidusStripe.configure do |config|
  config.webhook_events = %i[charge.succeeded]
end
```

That will register a new `:"stripe.charge.succeeded"` event in the [Solidus
bus](https://guides.solidus.io/customization/subscribing-to-events). The
Solidus event will be published whenever a matching incoming webhook event is
received. You can subscribe to it as regular:

```ruby
# app/subscribers/update_account_balance_subscriber.rb
class UpdateAccountBalanceSubscriber
  include Omnes::Subscriber

  handle :"stripe.charge.succeeded", with: :call

  def call(event)
    # ...
  end
end

# config/initializers/solidus_stripe.rb
# ...
Rails.application.config.to_prepare do
  UpdateAccountBalanceSubscriber.new.subscribe_to(Spree::Bus)
end
```

The passed event object is a thin wrapper around the [Stripe
event](https://www.rubydoc.info/gems/stripe/Stripe/Event) and the associated
Solidus Stripe payment method. It will delegate all unknown methods to the
underlying stripe event object. It can also be used in async [
adapters](https://github.com/nebulab/omnes#adapters), which is recommended as
otherwise the response to Stripe will be delayed until subscribers are done.

You can also configure the signature verification tolerance in seconds (it
defaults to the [same value as Stripe
default](https://stripe.com/docs/webhooks/signatures#replay-attacks)):

```ruby
# config/initializers/solidus_stripe.rb
SolidusStripe.configure do |config|
  config.webhook_signature_tolerance = 150
end
```

## Implementation

### Payment state-machine vs. PaymentIntent statuses

When compared to the Payment state machine, Stripe payment intents have different set of states and transitions.
The most important difference is that on Stripe a failure is not a final state, rather just a way to start over.

In order to map these concepts SolidusStripe will match states in a slightly unexpected way, as shown below.

| Stripe PaymentIntent Status | Solidus Payment State |
| --------------------------- | --------------------- |
| requires_payment_method     | checkout              |
| requires_action             | checkout              |
| processing                  | checkout              |
| requires_confirmation       | checkout              |
| requires_capture            | pending               |
| succeeded                   | completed             |

Reference:

- https://stripe.com/docs/payments/intents?intent=payment
- https://github.com/solidusio/solidus/blob/master/core/lib/spree/core/state_machines/payment.rb

## Development

Retrieve your API Key and Publishable Key from your [Stripe testing dashboard](https://stripe.com/docs/testing). You can
get your webhook signing secret executing the `stripe listen` command.

Set `SOLIDUS_STRIPE_API_KEY`, `SOLIDUS_STRIPE_PUBLISHABLE_KEY` and `SOLIDUS_STRIPE_WEBHOOK_SIGNING_SECRET` environment
variables (e.g. via `direnv`), this will trigger the default initializer to create a static preference for SolidusStripe.

Run `bin/dev` to start both the sandbox rail server and the file watcher through Foreman. That will update the sandbox whenever
a file is changed. When using `bin/dev` you can safely add `debugger` statements, even if Foreman won't provide a TTY, by connecting
to the debugger session through `rdbg --attach` from another terminal.

Visit `/admin/payments` and create a new Stripe payment using the static preferences.

See the [Webhooks section](#webhooks) to learn how to configure Stripe webhooks.

### Testing the extension

First bundle your dependencies, then run `bin/rake`. `bin/rake` will default to building the dummy
app if it does not exist, then it will run specs. The dummy app can be regenerated by using
`bin/rake extension:test_app`.

```shell
bin/rake
```

To run [Rubocop](https://github.com/bbatsov/rubocop) static code analysis run

```shell
bundle exec rubocop
```

When testing your application's integration with this extension you may use its factories.
Simply add this require statement to your `spec/spec_helper.rb`:

```ruby
require 'solidus_stripe/testing_support/factories'
```

Or, if you are using `FactoryBot.definition_file_paths`, you can load Solidus core
factories along with this extension's factories using this statement:

```ruby
SolidusDevSupport::TestingSupport::Factories.load_for(SolidusStripe::Engine)
```

### Running the sandbox

To run this extension in a sandboxed Solidus application, you can run `bin/sandbox`. The path for
the sandbox app is `./sandbox` and `bin/rails` will forward any Rails commands to
`sandbox/bin/rails`.

Here's an example:

```
$ bin/rails server
=> Booting Puma
=> Rails 6.0.2.1 application starting in development
* Listening on tcp://127.0.0.1:3000
Use Ctrl-C to stop
```

### Releasing new versions

Please refer to the dedicated [page](https://github.com/solidusio/solidus/wiki/How-to-release-extensions) on Solidus wiki.

## License

Copyright (c) 2014 Spree Commerce Inc., released under the New BSD License
Copyright (c) 2021 Solidus Team, released under the New BSD License.
