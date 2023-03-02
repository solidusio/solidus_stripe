🚧 **WARNING: WORK IN PROGRESS** 🚧

You're looking at the source for `solidus_stripe` v5, which will only support the **starter frontend**
but at the moment **it is not ready to be used**.

Please use [`solidus_stripe` v4 on the corresponding branch](https://github.com/solidusio/solidus_stripe/tree/v4).

🚧 **WARNING: WORK IN PROGRESS** 🚧

> ⚠️ **WARNING** ⚠️
>
> Please note that at the moment, solidus_stripe only supports integration with a single Stripe account. This means it is not suitable for use in a multi-seller marketplace environment. We are working to add support for multiple Stripe accounts as soon as possible.

# Solidus Stripe

[![CircleCI](https://circleci.com/gh/solidusio/solidus_stripe.svg?style=shield)](https://circleci.com/gh/solidusio/solidus_stripe)
[![codecov](https://codecov.io/gh/solidusio/solidus_stripe/branch/master/graph/badge.svg)](https://codecov.io/gh/solidusio/solidus_stripe)

<!-- Explain what your extension does. -->

## Installation

Add solidus_stripe to your Gemfile:

```ruby
gem 'solidus_stripe'
```

> ⚠️ **WARNING** ⚠️
>
> If you need support for `solidus_frontend` please add `< 5` as a version requirement in your gemfile:
>
> `gem 'solidus_stripe', '< 5'`
>
> or if your tracking the github version please switch to the `v4` branch:
>
> `gem 'solidus_stripe', git: 'https://github.com/solidusio/solidus_stripe.git', branch: 'v4'`
>

Bundle your dependencies and run the installation generator:

```shell
bin/rails generate solidus_stripe:install
```

### Webhooks

This library makes use of some [Stripe webhooks](https://stripe.com/docs/webhooks).

On development, you can [test them by using Stripe CLI](https://stripe.com/docs/webhooks/test).

Before going to production, you'll need to [register the
`/solidus_stripe/webhooks` endpoint with
Stripe](https://stripe.com/docs/webhooks/go-live), and make sure to subscribe
to the following events:

[TBD]

In both environments, you'll need to create a
`solidus_stripe.webhook_endpoint_secret` credential with [the webhook signing
secret](https://stripe.com/docs/webhooks/signatures):

```bash
# For development, add `--environment development`
bin/rails credentials:edit
```

```yaml
# config/credentials.yml.enc
solidus_stripe:
  webhook_endpoint_secret: "whsec_..."
```

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
event](https://www.rubydoc.info/gems/stripe/Stripe/Event) and will
delegate all methods to it. It can also be used in async [
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

Reference: https://stripe.com/docs/payments/intents?intent=payment

![image](https://user-images.githubusercontent.com/1051/217322027-f49081f5-0795-49f4-994e-285a9de5347c.png)

### ⚠️ Warning: Authorization happens before the order is completed

This setup implies a payment is authorized after the payment information is submitted to Stripe, although the order
still needs to be completed. That can become an issue if a customer abandons the checkout at the `confirm` step and
no action is taken to free up the money on the backend.

In order to mitigate this issue, we suggest adapting the frontend by merging the *confirm* and *payment* steps:

1. embed the agreement to the terms of service
2. add order summary to the payment step
3. apply the following patch

```patch
--- a/templates/app/controllers/checkouts_controller.rb
+++ b/templates/app/controllers/checkouts_controller.rb
@@ -48,6 +48,8 @@ def redirect_on_failure
   end

   def transition_forward
+    @order.next if @order.has_checkout_step?("payment") && @order.payment?
+
     if @order.can_complete?
       @order.complete
     else
```

## Development

Retrieve your API Key and Publishable Key from your [Stripe testing dashboard](https://stripe.com/docs/testing).

Set `SOLIDUS_STRIPE_API_KEY` and `SOLIDUS_STRIPE_PUBLISHABLE_KEY` environment variables (e.g. via `direnv`), this
will trigger the default initializer to create a static preference for SolidusStripe.

Run `bin/dev` to start both the sandbox rail server and the file watcher through Foreman. That will update the sandbox whenever
a file is changed. When using `bin/dev` you can safely add `debugger` statements, even if Foreman won't provide a TTY, by connecting
to the debugger session through `rdbg --attach` from another terminal.

Visit `/admin/payments` and create a new Stripe payment using the static preferences.

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
