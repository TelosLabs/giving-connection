import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["input", "formatError"]

    connect() {
        this.validatePhoneNumber()
    }

    validatePhoneNumber() {
        const number = this.inputTarget.value.trim();
        const cleanedNumber = number.replace(/-/g, '');
        // Ensure only one '+' at the beginning
        const plusCount = (number.match(/\+/g) || []).length;
        const hasLeadingPlus = number.startsWith('+');
        const validPlus = (plusCount === 0) || (plusCount === 1 && hasLeadingPlus);
        const cleanedNumber = number.replace(/-/g, '');
        const isValidFormat = validPlus && /^\+?\d{10,15}$/.test(cleanedNumber);

        if (!isValidFormat && number.length > 0) {
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

    filterInput(event) {
        const allowedChars = /[0-9+\-]/;
        const char = String.fromCharCode(event.which);

        if (!allowedChars.test(char)) {
            event.preventDefault();
        }
    }
}