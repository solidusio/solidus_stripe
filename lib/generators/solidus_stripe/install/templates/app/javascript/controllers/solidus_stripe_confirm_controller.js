import { Controller } from "@hotwired/stimulus"
import { loadStripe } from "@stripe/stripe-js"

export default class extends Controller {
  static values = {
    clientSecret: String,
    publishableKey: String,
    returnUrl: String,
    errorBaseUrl: String,
  }

  async connect() {
    this.stripe = await loadStripe(this.publishableKeyValue)
  }

  // action
  async confirm(e) {
    // Bail out if not on the confirm method form.
    if (e.target !== this.element.form) return

    e.preventDefault()

    const { error } = await this.stripe.confirmPayment({
      clientSecret: this.clientSecretValue,
      confirmParams: { return_url: this.returnUrlValue },
    })

    if (error) {
      // This point will only be reached if there is an immediate error when
      // confirming the payment. Show error to your customer.
      const messageParam = `error_message=${encodeURIComponent(error.message)}`
      location.href = `${this.errorBaseUrlValue}&${messageParam}`
    } else {
      // Your customer will be redirected to your `return_url`. For some payment
      // methods like iDEAL, your customer will be redirected to an intermediate
      // site first to authorize the payment, then redirected to the `return_url`.
    }
  }
}
