import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {}

  static targets = ["modal"] // Define the modal as a target

  close(e) {
    e.preventDefault(); // Prevent default behavior of the link

    // Safely remove the modal from the DOM using the modal target
    this.modalTarget.remove();

    // Optional: Redirect to /projects if needed
    if (window.location.pathname === "/projects/new") {
      window.location.href = "/projects";
    }
   }
 }
