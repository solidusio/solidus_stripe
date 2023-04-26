# Solidus Stripe

[![CircleCI](https://circleci.com/gh/solidusio/solidus_stripe.svg?style=shield)](https://circleci.com/gh/solidusio/solidus_stripe)
[![codecov](https://codecov.io/gh/solidusio/solidus_stripe/branch/main/graph/badge.svg)](https://codecov.io/gh/solidusio/solidus_stripe)
[![yardoc](https://img.shields.io/badge/docs-rubydoc.info-informational)](https://rubydoc.info/gems/solidus_stripe)

<!-- Explain what your extension does. -->

## Installation

Add solidus_stripe to your bundle and run the installation generator:

```shell
bundle add solidus_stripe
bin/rails generate solidus_stripe:install
```

Then set the following environment variables both locally and in production in order
to setup the `solidus_stripe_env_credentials` static preference as defined in the initializer:

```shell
SOLIDUS_STRIPE_API_KEY                # will prefill the `api_key` preference
SOLIDUS_STRIPE_PUBLISHABLE_KEY        # will prefill the `publishable_key` preference
SOLIDUS_STRIPE_WEBHOOK_SIGNING_SECRET # will prefill the `webhook_signing_secret` preference
```

Once those are available you can create a new Stripe payment method in the /admin interface
and select the `solidus_stripe_env_credentials` static preference.

⚠️ Be sure to set the enviroment variables to the values for test mode in your development environment.

### Webhooks setup

The webhooks URLs are automatically generated based on the enviroment, 
by default it will be scoped to `live` in production and `test` everywhere else.

#### Production enviroment

Before going to production, you'll need to [register the webhook endpoint with
Stripe](https://stripe.com/docs/webhooks/go-live), and make sure to subscribe
to the events listed in [the `SolidusStripe::Webhook::Event::CORE`
constant](https://github.com/solidusio/solidus_stripe/blob/main/lib/solidus_stripe/webhook/event.rb).

So in your Stripe dashboard you'll need to set the webhook URL to:

    https://store.example.com/solidus_stripe/live/webhooks

#### Non-production enviroments

While for development [you should use the stripe CLI to forward the webhooks to your local server](https://stripe.com/docs/webhooks/test#webhook-test-cli):

```shell
# Please refer to `stripe listen --help` for more options
stripe listen --forward-to http://localhost:3000/solidus_stripe/test/webhooks
```

### Supporting `solidus_frontend`

If you need support for `solidus_frontend` please refer to the [README of solidus_stripe v4](https://github.com/solidusio/solidus_stripe/tree/v4#readme).

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

### Showing reusable sources in the admin interface

Refer to the previous section for information on how to set up a new payment method type.
However, it's important to note that if you have to display a wallet source connected to a
Stripe Payment Method other than "card" on the admin interface, you must include the partial in:

`app/views/spree/admin/payments/source_forms/existing_payment/stripe/`

### Customizing Webhooks

Solidus Stripe comes with support for a few [webhook events](https://stripe.com/docs/webhooks), to which there's a default handler. You can customize the behavior of those handlers by or add to their behavior by replacing or adding subscribers in the internal Solidus event bus.

Each event will have the original Stripe name, prefixed by `stripe.`. For example, the `payment_intent.succeeded` event will be published as `stripe.payment_intent.succeeded`.

Here's the list of events that are supported by default:

        payment_intent.succeeded
        payment_intent.payment_failed
        payment_intent.canceled
        charge.refunded

#### Adding a new event handler

In order to add a new handler you need to register the event you want to listen to, 
both [in Stripe](https://stripe.com/docs/webhooks/go-live) and in your application:

```ruby
# config/initializers/solidus_stripe.rb
SolidusStripe.configure do |config|
  config.webhook_events = %i[charge.succeeded]
end
```

That will register a new `:"stripe.charge.succeeded"` event in the [Solidus
bus](https://guides.solidus.io/customization/subscribing-to-events). The
Solidus event will be published whenever a matching incoming webhook event is
received. You can subscribe to it [as usual](https://guides.solidus.io/customization/subscribing-to-events):

```ruby
# app/subscribers/update_account_balance_subscriber.rb
class UpdateAccountBalanceSubscriber
  include Omnes::Subscriber

  handle :"stripe.charge.succeeded", with: :call

  def call(event)
    # Please refere to the Stripe gem and API documentation for more details on the
    # structure of the event object. All methods called on `event` will be forwarded
    # to the Stripe event object:
    # - https://www.rubydoc.info/gems/stripe/Stripe/Event
    # - https://stripe.com/docs/webhooks/stripe-events

    Rails.logger.info "Charge succeeded: #{event.data.to_json}"
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

#### Configuring the webhook signature tolerance

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
