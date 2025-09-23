import { Controller } from "@hotwired/stimulus";
import { useDebounce } from "stimulus-use";

export default class extends Controller {
    static targets = ["input", "formatError"]
    static debounces = ["validateEmail"]

    connect() {
        useDebounce(this)
        this.validateEmail()
    }

    validateEmail() {
        const email = this.inputTarget.value.trim();
        // Basic format check: local@domain
        const basicFormat = /^[^\s@]+@[^\s@]+$/.test(email);
        let isValidFormat = false;
        if (basicFormat) {
            const [local, domain] = email.split('@');
            // Domain must contain exactly one period, not start/end with period, and no consecutive periods
            const periodCount = (domain.match(/\./g) || []).length;
            const hasConsecutivePeriods = domain.includes('..');
            const startsOrEndsWithPeriod = domain.startsWith('.') || domain.endsWith('.');
            isValidFormat = periodCount === 1 && !hasConsecutivePeriods && !startsOrEndsWithPeriod;
        }

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
