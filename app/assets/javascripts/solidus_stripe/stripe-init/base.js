window.SolidusStripe = window.SolidusStripe || {};

SolidusStripe.paymentMethod = {
  config: $('[data-stripe-config').data('stripe-config'),
  requestShipping: false
}

var authToken = $('meta[name="csrf-token"]').attr('content');

var stripe = Stripe(SolidusStripe.paymentMethod.config.publishable_key)
var elements = stripe.elements({locale: 'en'});

var element = $('#payment_method_' + SolidusStripe.paymentMethod.config.id);
var form = element.parents('form');
var errorElement = form.find('#card-errors');
var submitButton = form.find('input[type="submit"]');

function stripeTokenHandler(token) {
  var baseSelector = `<input type='hidden' class='stripeToken' name='payment_source[${SolidusStripe.paymentMethod.config.id}]`;

  element.append(`${baseSelector}[gateway_payment_profile_id]' value='${token.id}'/>`);
  element.append(`${baseSelector}[last_digits]' value='${token.card.last4}'/>`);
  element.append(`${baseSelector}[month]' value='${token.card.exp_month}'/>`);
  element.append(`${baseSelector}[year]' value='${token.card.exp_year}'/>`);
  form.find('input#cc_type').val(mapCC(token.card.brand || token.card.type));
};

function initElements() {
  var style = {
    base: {
      color: 'black',
      fontFamily: '"Helvetica Neue", Helvetica, sans-serif',
      fontSmoothing: 'antialiased',
      fontSize: '14px',
      '::placeholder': {
        color: 'silver'
      }
    },
    invalid: {
      color: 'red',
      iconColor: 'red'
    }
  };

  elements.create('cardExpiry', {style: style}).mount('#card_expiry');
  elements.create('cardCvc', {style: style}).mount('#card_cvc');

  var cardNumber = elements.create('cardNumber', {style: style});
  cardNumber.mount('#card_number');

  return cardNumber;
}

function setUpPaymentRequest(config, onPrButtonMounted) {
  if (typeof config !== 'undefined') {
    var paymentRequest = stripe.paymentRequest({
      country: config.country,
      currency: config.currency,
      total: {
        label: config.label,
        amount: config.amount
      },
      requestPayerName: true,
      requestPayerEmail: true,
      requestShipping: config.requestShipping,
      shippingOptions: [
      ]
    });

    var prButton = elements.create('paymentRequestButton', {
      paymentRequest: paymentRequest
    });

    paymentRequest.canMakePayment().then(function(result) {
      var id = 'payment-request-button';

      if (result) {
        prButton.mount('#' + id);
      } else {
        document.getElementById(id).style.display = 'none';
      }
      if (typeof onPrButtonMounted === 'function') {
        onPrButtonMounted(id, result);
      }
    });

    paymentRequest.on('paymentmethod', function(result) {
      errorElement.text('').hide();
      handlePayment(result);
    });

    paymentRequest.on('shippingaddresschange', function(ev) {
      fetch('/stripe/shipping_rates', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          authenticity_token: authToken,
          shipping_address: ev.shippingAddress
        })
      }).then(function(response) {
        return response.json();
      }).then(function(result) {
        if (result.error) {
          showError(result.error);
          return false;
        } else {
          ev.updateWith({
            status: 'success',
            shippingOptions: result.shipping_rates
          });
        }
      });
    });

    return paymentRequest;
  }
};

function handleServerResponse(response, payment) {
  if (response.error) {
      showError(response.error);
      completePaymentRequest(payment, 'fail');
  } else if (response.requires_action) {
    stripe.handleCardAction(
      response.stripe_payment_intent_client_secret
    ).then(function(result) {
      if (result.error) {
        showError(result.error.message);
      } else {
        fetch('/stripe/confirm_intents', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            spree_payment_method_id: SolidusStripe.paymentMethod.config.id,
            stripe_payment_intent_id: result.paymentIntent.id,
            authenticity_token: authToken
          })
        }).then(function(confirmResult) {
          return confirmResult.json();
        }).then(handleServerResponse);
      }
    });
  } else {
    completePaymentRequest(payment, 'success');
    submitPayment(payment);
  }
}

function completePaymentRequest(payment, state) {
  if (payment && typeof payment.complete === 'function') {
    payment.complete(state);
  }
}

function showError(error) {
  errorElement.text(error).show();

  if (submitButton.length) {
    setTimeout(function() {
      $.rails.enableElement(submitButton[0]);
      submitButton.removeAttr('disabled').removeClass('disabled');
    }, 100);
  }
};

function mapCC(ccType) {
  if (ccType === 'MasterCard') {
    return 'mastercard';
  } else if (ccType === 'Visa') {
    return 'visa';
  } else if (ccType === 'American Express') {
    return 'amex';
  } else if (ccType === 'Discover') {
    return 'discover';
  } else if (ccType === 'Diners Club') {
    return 'dinersclub';
  } else if (ccType === 'JCB') {
    return 'jcb';
  }
};
