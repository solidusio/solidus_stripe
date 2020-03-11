$(function() {
  var stripeV3Api = $('[data-v3-api]').data('v3-api');

  if (stripeV3Api) {
    $.getScript('https://js.stripe.com/v3/')
      .done(function() {
        switch (stripeV3Api) {
          case 'elements':
            new SolidusStripe.Elements().init();
            break;
          case 'payment-intents':
            new SolidusStripe.PaymentIntents().init();
            break;
          case 'payment-request-button':
            new SolidusStripe.CartPageCheckout().init();
            break;
        }
    });
  }
});
