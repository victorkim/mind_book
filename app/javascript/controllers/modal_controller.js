import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {}

  close(e) { //close action (or event)
    e.preventDefault(); //prevent default action of the link (ie. navigation)
    const modal = document.getElementById("modal");
    modal.innerHTML = ""; //cleans the html inside of the element #modal
    modal.removeAttribute("src"); // Remove the src attribute from the modal to ensure that the modal does not attempt to reload its content from the previous source
    modal.removeAttribute("complete"); // Marking the modal as no longer "complete", which may reset its state or allow new content to be loaded without conflicts

    if (window.location.pathname === "/projects/new") { // Checks if the current URL is /projects/new and if it is, redirects to /projects. If not, does not redirect
      window.location.href = "/projects";
    }
   }
 }
