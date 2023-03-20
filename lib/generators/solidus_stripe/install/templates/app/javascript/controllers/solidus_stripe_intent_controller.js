import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    clientSecret: String,
    publishableKey: String,
    emailAddress: String,
    returnUrl: String,
    flow: String,

    // For now we don't have a controller to interact with
    // and we can't use outlets, so we fallback on acquiring selectors.
    submitSelector: String,
    radioSelector: String,
  }

  static targets = ['paymentElement', 'message']

  get submitOutletElement() {
    return document.querySelector(this.submitSelectorValue)
  }

  get radioOutletElement() {
    return document.querySelector(this.radioSelectorValue)
  }

  connect() {
    this.stripe = Stripe(this.publishableKeyValue)
    this.setupPaymentElement()
  }

  // @action
  async handleSubmit(e) {
    // Bail out if the current payment method is not selected.
    if (!this.radioOutletElement.checked) return

    e.preventDefault()

    this.setLoading(true)

    const { error } = await this.confirmIntent()

    if (error.type === 'card_error' || error.type === 'validation_error') {
      this.messageTarget.textContent = error.message
    } else {
      this.messageTarget.textContent = 'An unexpected error occurred.'
    }

    this.setLoading(false)
  }

  confirmIntent() {
    // NOTE: confirming the intent will redirect the whole page and come back to
    //       the `return_url` unless an immediate error gets in the way.
    if (this.flowValue == 'payment') {
      return this.stripe.confirmPayment({
        elements: this.elements,
        confirmParams: {
          return_url: this.returnUrlValue,
          receipt_email: this.emailAddressValue,
        },
      })
    } else if (this.flowValue == 'setup') {
      return this.stripe.confirmSetup({
        elements: this.elements,
        confirmParams: {
          return_url: this.returnUrlValue,
          // receipt_email: this.emailAddressValue, # TODO: Add support for this when using the intent
        },
      })
    } else {
      throw new Error("flowValue should be either 'payment' or 'setup'.")
    }
  }

  setupPaymentElement() {
    this.elements = this.stripe.elements({
      appearance: { theme: 'stripe' },
      clientSecret: this.clientSecretValue,
    })
    this.paymentElement = this.elements.create('payment', { layout: 'tabs' })
    this.paymentElementTarget.innerHTML = '' // Remove child nodes used for loading
    this.paymentElement.mount(this.paymentElementTarget)
  }

  setLoading(isLoading) {
    const element = this.submitOutletElement

    if (isLoading) {
      element.setAttribute('disabled', '')
    } else {
      element.removeAttribute('disabled')
    }
  }
}
