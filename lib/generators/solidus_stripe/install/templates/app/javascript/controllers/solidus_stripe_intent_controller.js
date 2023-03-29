import { Controller } from "@hotwired/stimulus"
import { loadStripe } from "@stripe/stripe-js"

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

  static targets = ["paymentElement", "message"]

  get submitOutletElement() {
    return document.querySelector(this.submitSelectorValue)
  }

  get radioOutletElement() {
    return document.querySelector(this.radioSelectorValue)
  }

  async connect() {
    this.stripe = await loadStripe(this.publishableKeyValue)
    this.setupPaymentElement()
  }

  // @action
  async handleSubmit(e) {
    // Bail out if not on the payment method form.
    if (e.target !== this.radioOutletElement.form) return

    // Bail out if the current payment method is not selected.
    if (!this.radioOutletElement.checked) return

    e.preventDefault()

    this.setLoading(true)

    const { error } = await this.confirmIntent()

    if (error.type === "card_error" || error.type === "validation_error") {
      this.messageTarget.textContent = error.message
    } else {
      this.messageTarget.textContent = "An unexpected error occurred."
    }

    this.setLoading(false)
  }

  confirmIntent() {
    let confirmMethod

    if (this.flowValue === "payment") confirmMethod = "confirmPayment"
    if (this.flowValue === "setup") confirmMethod = "confirmSetup"

    if (!this.flowValue)
      throw new Error("flowValue should be either 'payment' or 'setup'.")

    // NOTE: confirming the intent will redirect the whole page and come back to
    //       the `return_url` unless an immediate error gets in the way.
    return this.stripe[confirmMethod]({
      elements: this.elements,
      confirmParams: { return_url: this.returnUrlValue },
    })
  }

  setupPaymentElement() {
    this.elements = this.stripe.elements({
      appearance: { theme: "stripe" },
      clientSecret: this.clientSecretValue,
    })
    this.paymentElement = this.elements.create("payment", { layout: "tabs" })
    this.paymentElementTarget.innerHTML = "" // Remove child nodes used for loading
    this.paymentElement.mount(this.paymentElementTarget)
  }

  setLoading(isLoading) {
    const element = this.submitOutletElement

    if (isLoading) {
      element.setAttribute("disabled", "")
    } else {
      element.removeAttribute("disabled")
    }
  }
}
