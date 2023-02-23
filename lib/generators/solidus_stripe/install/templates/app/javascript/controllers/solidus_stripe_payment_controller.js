import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    publishableKey: String,
    solidusPaymentMethodId: String,
    paymentIntentPath: String,
    emailAddress: String,
    paymentUrl: String,
    paymentElementOptions: {
      type: Object,
      default: { layout: 'tabs' },
    },

    // For now we don't have a controller to interact with
    // so we fallback on acquiring the selector.
    paymentFormSelector: String,
  }

  static targets = ['paymentElement', 'message', 'paymentIntentInput']

  // ------- Manual outlet elements -------

  get submitButtonOutletElement() {
    return this.paymentFormOutletElement.querySelector('[type="submit"]')
  }

  get paymentMethodRadioOutletElement() {
    return this.paymentFormOutletElement.querySelector(
      `#order_payments_attributes__payment_method_id_${this.solidusPaymentMethodIdValue}`,
    )
  }

  get paymentFormOutletElement() {
    return document.querySelector(this.paymentFormSelectorValue)
  }

  async connect() {
    this.stripe = Stripe(this.publishableKeyValue)

    await this.setupPaymentElement()
    this.checkStatus()
  }

  get csrfEntry() {
    const csrfParam = document.querySelector('meta[name=csrf-param]').content
    const csrfToken = document.querySelector('meta[name=csrf-token]').content
    return { [csrfParam]: csrfToken }
  }

  async handleSubmit(e) {
    // Bail out if the current payment method is not selected.
    if (!this.paymentMethodRadioOutletElement.checked) return

    e.preventDefault()
    this.setLoading(true)

    const { error } = await this.stripe.confirmPayment({
      elements: this.elements,
      confirmParams: {
        // Make sure to change this to your payment completion page
        return_url: this.paymentUrlValue,
        receipt_email: this.emailAddressValue,
      },
    })

    // This point will only be reached if there is an immediate error when
    // confirming the payment. Otherwise, your customer will be redirected to
    // your `return_url`. For some payment methods like iDEAL, your customer will
    // be redirected to an intermediate site first to authorize the payment, then
    // redirected to the `return_url`.
    if (error.type === 'card_error' || error.type === 'validation_error') {
      this.showMessage(error.message)
    } else {
      this.showMessage('An unexpected error occurred.')
    }

    this.setLoading(false)

    this.paymentFormOutletElement.submit()
  }

  get locationClientSecret() {
    return new URLSearchParams(window.location.search).get(
      'payment_intent_client_secret',
    )
  }

  // Fetches the payment intent status after payment submission
  async checkStatus() {
    if (!this.locationClientSecret) return

    const { paymentIntent } = await this.stripe.retrievePaymentIntent(
      this.locationClientSecret,
    )
    let successful = false

    switch (paymentIntent.status) {
      case 'requires_capture':
        this.showMessage('Payment successfully authorized!')
        successful = true
        break
      case 'succeeded':
        this.showMessage('Payment succeeded!')
        successful = true
        break
      case 'processing':
        this.showMessage('Your payment is processing.')
        successful = true
        break
      case 'requires_payment_method':
        this.showMessage('Your payment was not successful, please try again.')
        break
      default:
        console.error(`paymentIntent.status = ${paymentIntent.status}`)
        this.showMessage('Something went wrong.')
        break
    }

    if (successful) {
      this.paymentElementOptionsValue = {
        ...this.paymentElementOptionsValue,
        readOnly: true,
      }
      this.paymentIntentInputTarget.value = paymentIntent.id
      this.paymentFormOutletElement.submit()
    }
  }

  paymentElementOptionsChanged() {
    if (this.paymentElement)
      this.paymentElement.update(this.paymentElementOptionsValue)
  }

  // Fetches a payment intent and captures the client secret
  async setupPaymentElement() {
    const clientSecret = (
      await (
        await fetch(this.paymentIntentPathValue, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            ...this.csrfEntry,
            payment_method_id: this.solidusPaymentMethodIdValue,
          }),
        })
      ).json()
    ).client_secret

    this.elements = this.stripe.elements({
      appearance: { theme: 'stripe' },
      clientSecret,
    })
    this.paymentElement = this.elements.create(
      'payment',
      this.paymentElementOptionsValue,
    )
    this.paymentElementTarget.innerHTML = '' // Remove child nodes used for loading
    this.paymentElement.mount(this.paymentElementTarget)
  }

  // ------- UI helpers -------

  showMessage(messageText) {
    this.messageTarget.setAttribute('hidden', true)
    this.messageTarget.textContent = messageText

    setTimeout(() => {
      this.messageTarget.removeAttribute('hidden')
      this.messageTarget.textContent = ''
    }, 4000)
  }

  // Show a spinner on payment submission
  setLoading(isLoading) {
    if (isLoading) {
      // Disable the button and show a spinner
      this.submitButtonOutletElement.disabled = true
    } else {
      // Disable the button and show a spinner
      this.submitButtonOutletElement.disabled = false
    }
  }
}
