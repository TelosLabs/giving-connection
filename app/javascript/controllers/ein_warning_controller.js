import UniquenessWarningController from "../administrate/controllers/uniqueness_warning_controller";

export default class extends UniquenessWarningController {
    static targets = ["input", "formatError"]

    connect() {
        super.connect?.()
        this.validateFormat()
    }

    validateFormat() {
        const ein = this.inputTarget.value.trim()
        const isValidFormat = /^\d{2}-\d{7}$/.test(ein)

        if (!isValidFormat && ein.length > 0) {
            this.inputTarget.classList.add("border-red-500", 
                "text-red-600",
                "focus:border-red-500",
                "focus:ring-red-500"
            )
            this.formatErrorTarget.classList.remove("hidden")
            this.inputTarget.setAttribute("aria-invalid", "true")
        } else {
            this.inputTarget.classList.remove("border-red-500", 
                "text-red-600",
                "focus:border-red-500",
                "focus:ring-red-500"
            )
            this.formatErrorTarget.classList.add("hidden")
            this.inputTarget.removeAttribute("aria-invalid")
        }
    }
}
