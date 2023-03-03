import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    clientSecret: String,
    publishableKey: String,
    solidusPaymentMethodId: String,
    emailAddress: String,
    returnUrl: String,
    // For now we don't have a controller to interact with
    // so we fallback on acquiring the selector.
    paymentFormSelector: String,
  }

  static targets = ['paymentElement', 'message']

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

  connect() {
    this.stripe = Stripe(this.publishableKeyValue)
    this.setupPaymentElement()
  }

  // @action
  async handleSubmit(e) {
    // Bail out if the current payment method is not selected.
    if (!this.paymentMethodRadioOutletElement.checked) return

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
    return this.stripe.confirmPayment({
      elements: this.elements,
      confirmParams: {
        // NOTE: `.confirmPayment()` will redirect the whole page and come back to
        //       the `return_url` unless an immediate error gets in the way.
        return_url: this.returnUrlValue,
        receipt_email: this.emailAddressValue,
      },
    })
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
    const element = this.submitButtonOutletElement

    if (isLoading) {
      element.setAttribute('disabled', '')
    } else {
      element.removeAttribute('disabled')
    }
  }
}
