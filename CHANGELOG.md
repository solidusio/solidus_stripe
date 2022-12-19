# Changelog

## [v4.4.0](https://github.com/solidusio/solidus_stripe/tree/v4.4.0) (2022-12-19)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v4.3.0...v4.4.0)

**Fixed bugs:**

- Test issue, please disregard [\#145](https://github.com/solidusio/solidus_stripe/issues/145)
- Fix incorrect charge amount for currencies without fractions [\#138](https://github.com/solidusio/solidus_stripe/issues/138)
- ActionView::MissingTemplate in Spree::Checkout\#edit [\#127](https://github.com/solidusio/solidus_stripe/issues/127)

**Closed issues:**

- RFC: Overhauling solidus\_stripe [\#135](https://github.com/solidusio/solidus_stripe/issues/135)
- Initializer fails with uninitialized constant Spree::PaymentMethod [\#133](https://github.com/solidusio/solidus_stripe/issues/133)
- How to pass zip code when add a Credit Card [\#132](https://github.com/solidusio/solidus_stripe/issues/132)
- Undefined method `cvv\_path' [\#130](https://github.com/solidusio/solidus_stripe/issues/130)
- Javascript don't working after solidus\_stripe installation [\#126](https://github.com/solidusio/solidus_stripe/issues/126)
- Facing dependency  issue after upgrade solidus 3 [\#114](https://github.com/solidusio/solidus_stripe/issues/114)
- New release for solidus 3 [\#113](https://github.com/solidusio/solidus_stripe/issues/113)
- How to specify API version [\#93](https://github.com/solidusio/solidus_stripe/issues/93)
- Consistency between README and Wiki [\#67](https://github.com/solidusio/solidus_stripe/issues/67)

**Merged pull requests:**

- Fix adding a new customer card in admin [\#144](https://github.com/solidusio/solidus_stripe/pull/144) ([elia](https://github.com/elia))
- Fix incorrect charge amount for currencies without fractions [\#139](https://github.com/solidusio/solidus_stripe/pull/139) ([cmbaldwin](https://github.com/cmbaldwin))
- Fix setup instructions for Rails 7 [\#136](https://github.com/solidusio/solidus_stripe/pull/136) ([diegomichel](https://github.com/diegomichel))
- Update stale bot to extend org-level config [\#134](https://github.com/solidusio/solidus_stripe/pull/134) ([gsmendoza](https://github.com/gsmendoza))
- Revert "Add back custom view paths that were mistakenly removed" [\#129](https://github.com/solidusio/solidus_stripe/pull/129) ([elia](https://github.com/elia))
- Add back custom view paths that were mistakenly removed [\#128](https://github.com/solidusio/solidus_stripe/pull/128) ([elia](https://github.com/elia))
- Fix the CI after the Solidus v3.2 release [\#125](https://github.com/solidusio/solidus_stripe/pull/125) ([elia](https://github.com/elia))
- Update to use forked solidus\_frontend when needed [\#124](https://github.com/solidusio/solidus_stripe/pull/124) ([waiting-for-dev](https://github.com/waiting-for-dev))
- Fix CI and tests on Rails 7 [\#123](https://github.com/solidusio/solidus_stripe/pull/123) ([waiting-for-dev](https://github.com/waiting-for-dev))

## [v4.3.0](https://github.com/solidusio/solidus_stripe/tree/v4.3.0) (2021-10-19)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v4.2.0...v4.3.0)

**Implemented enhancements:**

- Remove Solidus 2.x deprecation to allow 3.0 usage [\#99](https://github.com/solidusio/solidus_stripe/pull/99) ([kennyadsl](https://github.com/kennyadsl))
- Update gem with the latest dev\_support [\#97](https://github.com/solidusio/solidus_stripe/pull/97) ([kennyadsl](https://github.com/kennyadsl))

**Fixed bugs:**

- Fix 3DS iframe selection [\#86](https://github.com/solidusio/solidus_stripe/pull/86) ([spaghetticode](https://github.com/spaghetticode))

**Closed issues:**

- Could not create payment [\#111](https://github.com/solidusio/solidus_stripe/issues/111)
- statement\_descriptor\_suffix [\#107](https://github.com/solidusio/solidus_stripe/issues/107)
- Shipping cost payment refund rejected from Stripe API because of negative charge value [\#101](https://github.com/solidusio/solidus_stripe/issues/101)
- Remove Solidus 2.x deprecations [\#98](https://github.com/solidusio/solidus_stripe/issues/98)
- about LICENSE [\#59](https://github.com/solidusio/solidus_stripe/issues/59)

**Merged pull requests:**

- Add statement\_descriptor\_suffix support to options\_for\_purchase\_or\_auth [\#106](https://github.com/solidusio/solidus_stripe/pull/106) ([torukMnk](https://github.com/torukMnk))
- Update install instructions [\#105](https://github.com/solidusio/solidus_stripe/pull/105) ([kennyadsl](https://github.com/kennyadsl))
- Allow Solidus 3 [\#104](https://github.com/solidusio/solidus_stripe/pull/104) ([kennyadsl](https://github.com/kennyadsl))
- Bump minimum solidus\_support version requirement [\#102](https://github.com/solidusio/solidus_stripe/pull/102) ([filippoliverani](https://github.com/filippoliverani))
-  Relax Ruby required version to support Ruby 3.0+ [\#96](https://github.com/solidusio/solidus_stripe/pull/96) ([filippoliverani](https://github.com/filippoliverani))
- Update refund\_decorator.rb prepend namespacing [\#91](https://github.com/solidusio/solidus_stripe/pull/91) ([brchristian](https://github.com/brchristian))
- Retrieve phone number paying with digital wallets [\#90](https://github.com/solidusio/solidus_stripe/pull/90) ([kennyadsl](https://github.com/kennyadsl))
- Fix Intents API link in README [\#87](https://github.com/solidusio/solidus_stripe/pull/87) ([kennyadsl](https://github.com/kennyadsl))
- Add missing 'var' [\#85](https://github.com/solidusio/solidus_stripe/pull/85) ([willread](https://github.com/willread))
- Fixes Rails 6.1 load warnings [\#84](https://github.com/solidusio/solidus_stripe/pull/84) ([marcrohloff](https://github.com/marcrohloff))
- Dedupe common code in stripe\_checkout\_spec.rb [\#80](https://github.com/solidusio/solidus_stripe/pull/80) ([brchristian](https://github.com/brchristian))
- Refactor spec with fill\_in\_card helper [\#78](https://github.com/solidusio/solidus_stripe/pull/78) ([brchristian](https://github.com/brchristian))
- Fix non-breaking space character in comment [\#76](https://github.com/solidusio/solidus_stripe/pull/76) ([brchristian](https://github.com/brchristian))
- Fix Copyright in README [\#73](https://github.com/solidusio/solidus_stripe/pull/73) ([kennyadsl](https://github.com/kennyadsl))
- Remove server and test\_mode from README [\#66](https://github.com/solidusio/solidus_stripe/pull/66) ([adammathys](https://github.com/adammathys))

## [v4.2.0](https://github.com/solidusio/solidus_stripe/tree/v4.2.0) (2020-07-20)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v4.1.0...v4.2.0)

**Fixed bugs:**

- Fix StripeCreditCard\#try\_void with Elements/V2 API [\#75](https://github.com/solidusio/solidus_stripe/pull/75) ([spaghetticode](https://github.com/spaghetticode))

**Closed issues:**

- A token may not be passed in as a PaymentMethod. Instead, create a PaymentMethod or convert your token to a PaymentMethod by setting the `card[token]` parameter to  [\#71](https://github.com/solidusio/solidus_stripe/issues/71)

**Merged pull requests:**

- Fix 3DS modal amount verification [\#72](https://github.com/solidusio/solidus_stripe/pull/72) ([spaghetticode](https://github.com/spaghetticode))

## [v4.1.0](https://github.com/solidusio/solidus_stripe/tree/v4.1.0) (2020-07-01)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v3.2.1...v4.1.0)

**Fixed bugs:**

- Card name ignored when adding new card to an order during checkout [\#68](https://github.com/solidusio/solidus_stripe/issues/68)
- Try to find address state also by name [\#65](https://github.com/solidusio/solidus_stripe/pull/65) ([spaghetticode](https://github.com/spaghetticode))
- Fix order cancel with Payment Intents captured payment [\#57](https://github.com/solidusio/solidus_stripe/pull/57) ([spaghetticode](https://github.com/spaghetticode))

**Merged pull requests:**

- Save correct cardholder name in Spree::CreditCard [\#69](https://github.com/solidusio/solidus_stripe/pull/69) ([spaghetticode](https://github.com/spaghetticode))
- Update Readme [\#63](https://github.com/solidusio/solidus_stripe/pull/63) ([aleph1ow](https://github.com/aleph1ow))
- Remove credit cards image [\#62](https://github.com/solidusio/solidus_stripe/pull/62) ([aleph1ow](https://github.com/aleph1ow))
- Remove Stripe::CardError leftover [\#58](https://github.com/solidusio/solidus_stripe/pull/58) ([spaghetticode](https://github.com/spaghetticode))
- Update gemspec URLs [\#54](https://github.com/solidusio/solidus_stripe/pull/54) ([elia](https://github.com/elia))
- fix typo [\#51](https://github.com/solidusio/solidus_stripe/pull/51) ([ccarruitero](https://github.com/ccarruitero))

## [v3.2.1](https://github.com/solidusio/solidus_stripe/tree/v3.2.1) (2020-06-29)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v4.0.0...v3.2.1)

**Fixed bugs:**

- \[ADMIN\] Order cancel doen't work with Payment Intents captured payments [\#56](https://github.com/solidusio/solidus_stripe/issues/56)

**Closed issues:**

- Could not find generator 'solidus\_stripe:install' [\#60](https://github.com/solidusio/solidus_stripe/issues/60)
- Payment Intent creation exception handling with class not present in the gem [\#55](https://github.com/solidusio/solidus_stripe/issues/55)
- Using static credentials  [\#52](https://github.com/solidusio/solidus_stripe/issues/52)
- Auto capture behavior in v4.0.0 [\#50](https://github.com/solidusio/solidus_stripe/issues/50)

## [v4.0.0](https://github.com/solidusio/solidus_stripe/tree/v4.0.0) (2020-04-29)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v3.2.0...v4.0.0)

**Fixed bugs:**

- Fix for 3D-Secure payments on cart page checkout [\#49](https://github.com/solidusio/solidus_stripe/pull/49) ([spaghetticode](https://github.com/spaghetticode))

**Closed issues:**

- Custom stripe element field options \(e.g for showing a credit card icon\) [\#41](https://github.com/solidusio/solidus_stripe/issues/41)
- Clearer documentation on how to implement [\#15](https://github.com/solidusio/solidus_stripe/issues/15)

**Merged pull requests:**

- Relax solidus\_support dependency [\#48](https://github.com/solidusio/solidus_stripe/pull/48) ([kennyadsl](https://github.com/kennyadsl))

## [v3.2.0](https://github.com/solidusio/solidus_stripe/tree/v3.2.0) (2020-04-10)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v3.1.0...v3.2.0)

**Fixed bugs:**

- Send form data also when paying with payment request button [\#47](https://github.com/solidusio/solidus_stripe/pull/47) ([spaghetticode](https://github.com/spaghetticode))

**Merged pull requests:**

- Replace deprecated route `/stripe/confirm_payment` [\#46](https://github.com/solidusio/solidus_stripe/pull/46) ([spaghetticode](https://github.com/spaghetticode))

## [v3.1.0](https://github.com/solidusio/solidus_stripe/tree/v3.1.0) (2020-04-10)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v3.0.0...v3.1.0)

**Fixed bugs:**

- Duplicates charges with Payment Intents [\#44](https://github.com/solidusio/solidus_stripe/issues/44)
- Create a single charge when using Stripe Payment Intents [\#45](https://github.com/solidusio/solidus_stripe/pull/45) ([spaghetticode](https://github.com/spaghetticode))

**Closed issues:**

- Stripe Elements submit button stuck in disabled state. [\#39](https://github.com/solidusio/solidus_stripe/issues/39)
- Visa credit card type is blank [\#36](https://github.com/solidusio/solidus_stripe/issues/36)
- Pay with Apple Pay from cart page [\#23](https://github.com/solidusio/solidus_stripe/issues/23)

**Merged pull requests:**

- Custom Stripe Elements field options [\#42](https://github.com/solidusio/solidus_stripe/pull/42) ([stuffmatic](https://github.com/stuffmatic))
- Improve the way Stripe Elements validation errors are displayed [\#40](https://github.com/solidusio/solidus_stripe/pull/40) ([stuffmatic](https://github.com/stuffmatic))
- Fix stripe-to-solidus card type mapping [\#38](https://github.com/solidusio/solidus_stripe/pull/38) ([stuffmatic](https://github.com/stuffmatic))
- Add hook to provide custom Stripe Elements options [\#37](https://github.com/solidusio/solidus_stripe/pull/37) ([stuffmatic](https://github.com/stuffmatic))
- Change order description that we pass to Stripe [\#35](https://github.com/solidusio/solidus_stripe/pull/35) ([kennyadsl](https://github.com/kennyadsl))

## [v3.0.0](https://github.com/solidusio/solidus_stripe/tree/v3.0.0) (2020-03-11)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v2.1.0...v3.0.0)

**Implemented enhancements:**

- Rename v3/stripe partial as v3/elements [\#30](https://github.com/solidusio/solidus_stripe/pull/30) ([spaghetticode](https://github.com/spaghetticode))

**Merged pull requests:**

- Allow to customize Stripe Elements styles via JS [\#34](https://github.com/solidusio/solidus_stripe/pull/34) ([spaghetticode](https://github.com/spaghetticode))
- Stop injecting css in host app while installing [\#33](https://github.com/solidusio/solidus_stripe/pull/33) ([kennyadsl](https://github.com/kennyadsl))
- Manage Stripe V3 JS code via Sprokets [\#32](https://github.com/solidusio/solidus_stripe/pull/32) ([spaghetticode](https://github.com/spaghetticode))

## [v2.1.0](https://github.com/solidusio/solidus_stripe/tree/v2.1.0) (2020-03-11)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v2.0.0...v2.1.0)

**Closed issues:**

- Preference :stripe\_country is not defined on Spree::PaymentMethod::StripeCreditCard \(RuntimeError\) [\#27](https://github.com/solidusio/solidus_stripe/issues/27)

**Merged pull requests:**

- Refactor Stripe V3 Intents, Elements and cart checkout JS code [\#31](https://github.com/solidusio/solidus_stripe/pull/31) ([spaghetticode](https://github.com/spaghetticode))

## [v2.0.0](https://github.com/solidusio/solidus_stripe/tree/v2.0.0) (2020-03-03)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v1.2.0...v2.0.0)

**Implemented enhancements:**

- Add support for Apple Pay through Stripe Payment Request Button [\#22](https://github.com/solidusio/solidus_stripe/issues/22)
- Cart page payment with Stripe payment request button \(Apple/Google Pay\)  [\#29](https://github.com/solidusio/solidus_stripe/pull/29) ([spaghetticode](https://github.com/spaghetticode))
- Allow Apple Pay and Google Pay via Payment Request Button [\#25](https://github.com/solidusio/solidus_stripe/pull/25) ([spaghetticode](https://github.com/spaghetticode))
- Use Payment Intents API with Active Merchant [\#20](https://github.com/solidusio/solidus_stripe/pull/20) ([spaghetticode](https://github.com/spaghetticode))

**Closed issues:**

- Handling of Strong Customer Authentication \(SCA\) [\#18](https://github.com/solidusio/solidus_stripe/issues/18)
- Stripe checkout fails when using a stored credit card number [\#16](https://github.com/solidusio/solidus_stripe/issues/16)
- Better PCI-Compliance with stripe.js version 3 [\#5](https://github.com/solidusio/solidus_stripe/issues/5)
- No gem found [\#4](https://github.com/solidusio/solidus_stripe/issues/4)

**Merged pull requests:**

- Remove ERB from Elements and Intents JS code [\#28](https://github.com/solidusio/solidus_stripe/pull/28) ([spaghetticode](https://github.com/spaghetticode))
- Remove `update_attributes!` deprecation [\#24](https://github.com/solidusio/solidus_stripe/pull/24) ([spaghetticode](https://github.com/spaghetticode))
- Add solidus\_dev\_support gem [\#21](https://github.com/solidusio/solidus_stripe/pull/21) ([spaghetticode](https://github.com/spaghetticode))
- Fix reusing cards with Stripe v3 [\#17](https://github.com/solidusio/solidus_stripe/pull/17) ([kennyadsl](https://github.com/kennyadsl))
- Extension maintenance [\#14](https://github.com/solidusio/solidus_stripe/pull/14) ([kennyadsl](https://github.com/kennyadsl))
- Update README installation instructions [\#13](https://github.com/solidusio/solidus_stripe/pull/13) ([hashrocketeer](https://github.com/hashrocketeer))
- Use preferred\_v3\_elements instead of preferences\[:v3\_elements\] [\#12](https://github.com/solidusio/solidus_stripe/pull/12) ([ChristianRimondi](https://github.com/ChristianRimondi))
- Remove `Spree.t` in favor of `I18n.t` [\#11](https://github.com/solidusio/solidus_stripe/pull/11) ([spaghetticode](https://github.com/spaghetticode))
- Remove Capybara deprecation warning [\#10](https://github.com/solidusio/solidus_stripe/pull/10) ([spaghetticode](https://github.com/spaghetticode))
- Add Stripe.js V3 with Elements [\#9](https://github.com/solidusio/solidus_stripe/pull/9) ([spaghetticode](https://github.com/spaghetticode))
- Remove unused CircleCI config [\#8](https://github.com/solidusio/solidus_stripe/pull/8) ([aitbw](https://github.com/aitbw))
- Add Rubocop for linting [\#7](https://github.com/solidusio/solidus_stripe/pull/7) ([aitbw](https://github.com/aitbw))
- Allow creating seeds with the install command [\#6](https://github.com/solidusio/solidus_stripe/pull/6) ([kennyadsl](https://github.com/kennyadsl))
- Add Solidus v2.8 to Travis config [\#3](https://github.com/solidusio/solidus_stripe/pull/3) ([aitbw](https://github.com/aitbw))
- Update README.md [\#2](https://github.com/solidusio/solidus_stripe/pull/2) ([brchristian](https://github.com/brchristian))
- Add missing API partial for stripe gateway [\#1](https://github.com/solidusio/solidus_stripe/pull/1) ([jontarg](https://github.com/jontarg))

## [v1.2.0](https://github.com/solidusio/solidus_stripe/tree/v1.2.0) (2017-07-24)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v1.1.1...v1.2.0)

## [v1.1.1](https://github.com/solidusio/solidus_stripe/tree/v1.1.1) (2016-09-22)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v1.1.0...v1.1.1)

## [v1.1.0](https://github.com/solidusio/solidus_stripe/tree/v1.1.0) (2016-07-26)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v1.0.1...v1.1.0)

## [v1.0.1](https://github.com/solidusio/solidus_stripe/tree/v1.0.1) (2016-01-13)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v0.9.0...v1.0.1)

## [v0.9.0](https://github.com/solidusio/solidus_stripe/tree/v0.9.0) (2015-08-28)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/v1.0.0...v0.9.0)

## [v1.0.0](https://github.com/solidusio/solidus_stripe/tree/v1.0.0) (2015-08-27)

[Full Changelog](https://github.com/solidusio/solidus_stripe/compare/c20c3f69811d68c374ffedc2e20c1bc6bdb45f95...v1.0.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
