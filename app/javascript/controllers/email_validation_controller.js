import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["input", "formatError"]

    connect() {
        this.validateEmail()
    }

    validateEmail() {
        const email = this.inputTarget.value.trim();
        const isValidFormat = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

        if (!isValidFormat && email.length > 0) {
            this.inputTarget.classList.add(
                "border-red-500",
                "text-red-600",
                "focus:border-red-500",
                "focus:ring-red-500"
            );
            this.formatErrorTarget.classList.remove("hidden");
            this.inputTarget.setAttribute("aria-invalid", "true");
        } else {
            this.inputTarget.classList.remove(
                "border-red-500",
                "text-red-600",
                "focus:border-red-500",
                "focus:ring-red-500"
            );
            this.formatErrorTarget.classList.add("hidden");
            this.inputTarget.removeAttribute("aria-invalid");
        }
    }
}