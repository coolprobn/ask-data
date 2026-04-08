import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "submit", "suggestions"]

  connect() {
    this.boundToggleSuggestions = this.toggleSuggestions.bind(this)
    if (this.hasTextareaTarget) {
      this.textareaTarget.addEventListener("input", this.boundToggleSuggestions)
    }
    this.toggleSuggestions()
  }

  disconnect() {
    if (this.hasTextareaTarget) {
      this.textareaTarget.removeEventListener("input", this.boundToggleSuggestions)
    }
  }

  toggleSuggestions() {
    if (!this.hasSuggestionsTarget || !this.hasTextareaTarget) return
    const blank = !this.textareaTarget.value.trim()
    this.suggestionsTarget.classList.toggle("hidden", !blank)
  }

  fill(event) {
    const q = event.params.question
    if (typeof q === "string" && this.hasTextareaTarget) {
      this.textareaTarget.value = q
    }
    this.toggleSuggestions()
  }

  submitStart() {
    if (!this.hasSubmitTarget) return
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Running…"
  }
}
