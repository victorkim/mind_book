// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

// Enhanced modal controller that supports different modal types and behaviors
export default class extends Controller {
  static targets = ["modal"]
  static values = {
    redirectAfterClose: String,
    closeAction: String
  }

  connect() {
    // Add event listener for ESC key to close modal
    this.escapeHandler = this.escapeClose.bind(this)
    document.addEventListener('keydown', this.escapeHandler)
    
    // Optional: add click outside to close
    this.outsideClickHandler = this.outsideClick.bind(this)
    document.addEventListener('click', this.outsideClickHandler)
  }
  
  disconnect() {
    // Clean up event listeners
    document.removeEventListener('keydown', this.escapeHandler)
    document.removeEventListener('click', this.outsideClickHandler)
  }
  
  escapeClose(e) {
    if (e.key === 'Escape') {
      this.close(e)
    }
  }
  
  outsideClick(e) {
    // Only if clicking outside the modal content
    if (this.element.contains(e.target) && !this.modalTarget.contains(e.target)) {
      this.close(e)
    }
  }

  close(e) {
    if (e) e.preventDefault()
    
    // Remove the modal from the DOM
    this.element.remove()
    
    // Handle redirection if specified
    if (this.hasRedirectAfterCloseValue && this.redirectAfterCloseValue) {
      window.location.href = this.redirectAfterCloseValue
    }
    
    // Handle custom close action if specified
    if (this.hasCloseActionValue && this.closeActionValue) {
      this.element.dispatchEvent(new CustomEvent(this.closeActionValue))
    }
  }
}