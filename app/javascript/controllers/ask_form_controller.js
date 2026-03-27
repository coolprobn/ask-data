import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "submit"]

  fill(event) {
    const q = event.params.question
    if (typeof q === "string" && this.hasTextareaTarget) {
      this.textareaTarget.value = q
    }
  }

  submitStart() {
    if (!this.hasSubmitTarget) return
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Running…"
  }
}
