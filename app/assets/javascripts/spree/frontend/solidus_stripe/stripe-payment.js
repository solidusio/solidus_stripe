window.SolidusStripe = window.SolidusStripe || {};

SolidusStripe.Payment = function() {
  this.config = $('[data-stripe-config]').data('stripe-config');
  this.element = $('#payment_method_' + this.config.id);
  this.authToken = $('meta[name="csrf-token"]').attr('content');

  this.stripe = Stripe(this.config.publishable_key);
  this.elements = this.stripe.elements(this.elementsBaseOptions());
};

SolidusStripe.Payment.prototype.elementsBaseOptions = function () {
  return {
    locale: 'en'
  };
};
