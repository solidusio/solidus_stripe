SolidusStripe.PaymentIntents = function() {
  SolidusStripe.Elements.call(this);
};

SolidusStripe.PaymentIntents.prototype = Object.create(SolidusStripe.Elements.prototype);
Object.defineProperty(SolidusStripe.PaymentIntents.prototype, 'constructor', {
  value: SolidusStripe.PaymentIntents,
  enumerable: false,
  writable: true
});

SolidusStripe.PaymentIntents.prototype.init = function() {
  this.setUpPaymentRequest();
  this.initElements();
};

SolidusStripe.PaymentIntents.prototype.onPrPayment = function(payment) {
  if (payment.error) {
    this.showError(payment.error.message);
  } else {
    var that = this;

    this.elementsTokenHandler(payment.paymentMethod);
    fetch('/stripe/confirm_intents', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        form_data: this.form.serialize(),
        spree_payment_method_id: this.config.id,
        stripe_payment_method_id: payment.paymentMethod.id,
        authenticity_token: this.authToken
      })
    }).then(function(response) {
      response.json().then(function(json) {
        that.handleServerResponse(json, payment);
      })
    });
  }
};

SolidusStripe.PaymentIntents.prototype.onFormSubmit = function(event) {
  if (this.element.is(':visible')) {
    event.preventDefault();

    this.errorElement.text('').hide();

    this.stripe.createPaymentMethod(
      'card',
      this.cardNumber
    ).then(this.onIntentsPayment.bind(this));
  }
};

SolidusStripe.PaymentIntents.prototype.submitPayment = function(_payment) {
  this.form.unbind('submit').submit();
};

SolidusStripe.PaymentIntents.prototype.onIntentsPayment = function(payment) {
  if (payment.error) {
    this.showError(payment.error.message);
  } else {
    var that = this;

    this.elementsTokenHandler(payment.paymentMethod);
    fetch('/stripe/confirm_intents', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        form_data: this.form.serialize(),
        spree_payment_method_id: this.config.id,
        stripe_payment_method_id: payment.paymentMethod.id,
        authenticity_token: this.authToken
      })
    }).then(function(response) {
      response.json().then(function(json) {
        that.handleServerResponse(json, payment);
      })
    });
  }
};
