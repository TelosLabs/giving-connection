import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["choiceCard", "nextButton", "choiceCardsContainer", "moreOptionsBtn", "hiddenCard", "languageInput", "languageInputContainer", "genderDescriptionContainer", "genderDescriptionInput", "citySelectionContainer", "cityOption", "disclaimerCheckbox", "startButton", "disclaimerExpandable", "disclaimerToggle"]

    connect() {
        console.log('Smart Match Controller connected!')
        this.selectedChoice = null
        this.selectedMultipleChoices = []
        this.updateCurrentState()
        this.initializeCardStyles()
        this.initializeDisclaimer()
        this.initializePreviousAnswers()

        // Check if we're on the results page and fix layout if needed
        if (window.location.pathname.includes('/smart-match/results')) {
            this.fixResultsPageLayout()
        }
    }

    // Fix layout issues on results page
    fixResultsPageLayout() {
        console.log('Fixing results page layout...')

        // Ensure proper grid layout
        const grid = document.querySelector('.smart-match-results .grid')
        if (grid) {
            grid.style.display = 'grid'
            grid.style.gridTemplateColumns = 'repeat(1, 1fr)'
            grid.style.gap = '1.5rem'

            // Responsive grid
            if (window.innerWidth >= 768) {
                grid.style.gridTemplateColumns = 'repeat(2, 1fr)'
            }
            if (window.innerWidth >= 1024) {
                grid.style.gridTemplateColumns = 'repeat(3, 1fr)'
            }
        }

        // Fix Match Quality Summary grid specifically
        const qualityGrid = document.querySelector('.smart-match-results .bg-gray-50 .grid.grid-cols-4')
        if (qualityGrid) {
            console.log('Fixing Match Quality Summary grid...')
            qualityGrid.style.display = 'grid'
            qualityGrid.style.gridTemplateColumns = 'repeat(4, 1fr)'
            qualityGrid.style.gridTemplateRows = '1fr'
            qualityGrid.style.gridAutoFlow = 'row'
            qualityGrid.style.gap = '1rem'

            // Force all children to be in the first row
            const children = qualityGrid.children
            for (let i = 0; i < children.length; i++) {
                children[i].style.gridRow = '1'
                children[i].style.gridColumn = `${i + 1}`
            }

            console.log('Match Quality Summary grid fixed')
        }

        // Fix card positioning
        const cards = document.querySelectorAll('.smart-match-results .bg-white.rounded-lg.shadow-md')
        cards.forEach(card => {
            card.style.position = 'relative'
            card.style.display = 'flex'
            card.style.flexDirection = 'column'
            card.style.height = '100%'
            card.style.overflow = 'hidden'
            card.style.minHeight = '400px'
        })

        // Fix badge positioning
        const badges = document.querySelectorAll('.smart-match-results .absolute.top-4.right-4')
        badges.forEach(badge => {
            badge.style.position = 'absolute'
            badge.style.top = '1rem'
            badge.style.right = '1rem'
            badge.style.zIndex = '30'
        })

        // Fix text overflow
        const textElements = document.querySelectorAll('.smart-match-results .break-words')
        textElements.forEach(element => {
            element.style.wordWrap = 'break-word'
            element.style.overflowWrap = 'break-word'
            element.style.hyphens = 'auto'
        })

        console.log('Results page layout fixed')
    }

    initializeDisclaimer() {
        // Initialize disclaimer checkbox and start button state
        if (this.hasDisclaimerCheckboxTarget && this.hasStartButtonTarget) {
            this.toggleStartButton()
        }
    }

    toggleStartButton() {
        if (this.hasDisclaimerCheckboxTarget && this.hasStartButtonTarget) {
            const checkbox = this.disclaimerCheckboxTarget
            const startButton = this.startButtonTarget

            if (checkbox.checked) {
                startButton.classList.remove('opacity-50', 'cursor-not-allowed')
                startButton.classList.add('cursor-pointer')
                startButton.href = startButton.dataset.href || '/smart-match/quiz'
            } else {
                startButton.classList.add('opacity-50', 'cursor-not-allowed')
                startButton.classList.remove('cursor-pointer')
                startButton.href = '#'
            }
        }
    }

    checkDisclaimer(event) {
        if (this.hasDisclaimerCheckboxTarget) {
            const checkbox = this.disclaimerCheckboxTarget
            if (!checkbox.checked) {
                event.preventDefault()
                alert('Please agree to the Terms of Service and disclaimer before proceeding.')
            }
        }
    }

    toggleDisclaimer() {
        if (this.hasDisclaimerExpandableTarget && this.hasDisclaimerToggleTarget) {
            const expandable = this.disclaimerExpandableTarget
            const toggle = this.disclaimerToggleTarget

            if (expandable.classList.contains('hidden')) {
                expandable.classList.remove('hidden')
                toggle.textContent = 'Hide full disclaimer'
            } else {
                expandable.classList.add('hidden')
                toggle.textContent = 'Show full disclaimer'
            }
        }
    }

    updateCurrentState() {
        this.currentStep = this.getCurrentStep()
        this.userIntent = this.getUserIntent()
    }

    initializeCardStyles() {
        // Apply initial styling to all cards based on current step and user intent
        const style = this.getCardStyle()
        console.log('initializeCardStyles - style:', style, 'cards found:', this.choiceCardTargets.length)
        this.choiceCardTargets.forEach((card, index) => {
            console.log(`Applying style to card ${index + 1}:`, card)
            this.applyStyle(card, false, style)
        })
    }

    // Helper functions for consistent styling
    applyWhiteStyle(card, isSelected) {
        console.log('applyWhiteStyle - isSelected:', isSelected)
        if (isSelected) {
            console.log('Applying selected white style')
            card.style.borderWidth = '4px'
            card.style.borderColor = '#1e40af'
            card.style.backgroundColor = '#eff6ff'
        } else {
            console.log('Applying unselected white style')
            card.style.borderWidth = '2px'
            card.style.borderColor = '#dbeafe'
            card.style.backgroundColor = 'white'
        }
        console.log('Final card styles:', {
            borderWidth: card.style.borderWidth,
            borderColor: card.style.borderColor,
            backgroundColor: card.style.backgroundColor
        })
    }

    applyBlueStyle(card, isSelected) {
        if (isSelected) {
            card.style.borderWidth = '4px'
            card.style.borderColor = '#113c7b'
            card.style.backgroundColor = '#2B5AA0'
            // Keep icon and text white when selected
            const icon = card.querySelector('svg')
            const text = card.querySelector('p')
            if (icon) icon.style.filter = 'brightness(0) invert(1)'
            if (text) {
                text.classList.remove('text-blue-dark')
                text.classList.add('text-white')
            }
        } else {
            card.style.borderWidth = '0px'
            card.style.borderColor = 'transparent'
            card.style.backgroundColor = '#3682D0'
            // Reset icon and text colors to white
            const icon = card.querySelector('svg')
            const text = card.querySelector('p')
            if (icon) icon.style.filter = 'brightness(0) invert(1)'
            if (text) {
                text.classList.remove('text-blue-dark')
                text.classList.add('text-white')
            }
        }
    }

    applyPinkStyle(card, isSelected) {
        if (isSelected) {
            card.style.borderWidth = '0px'
            card.style.borderColor = 'transparent'
            card.style.backgroundColor = '#E67E7A'
            // Make icon and text white when selected
            const icon = card.querySelector('svg')
            const text = card.querySelector('p')
            if (icon) icon.style.filter = 'brightness(0) invert(1)'
            if (text) {
                text.classList.remove('text-blue-dark')
                text.classList.add('text-white')
            }
        } else {
            card.style.borderWidth = '0px'
            card.style.borderColor = 'transparent'
            card.style.backgroundColor = '#F2A29E'
            // Reset icon and text colors to blue
            const icon = card.querySelector('svg')
            const text = card.querySelector('p')
            if (icon) icon.style.filter = 'none'
            if (text) {
                text.classList.remove('text-white')
                text.classList.add('text-blue-dark')
            }
        }
    }

    applySeafoamStyle(card, isSelected) {
        console.log('applySeafoamStyle - isSelected:', isSelected)
        if (isSelected) {
            console.log('Applying selected seafoam style')
            card.style.borderWidth = '4px'
            card.style.borderColor = '#113c7b'
            card.style.backgroundColor = '#9AE2E0'
        } else {
            console.log('Applying unselected seafoam style')
            card.style.borderWidth = '0px'
            card.style.borderColor = 'transparent'
            card.style.backgroundColor = '#C7F0EF'
        }
    }

    getCardStyle() {
        // Get style from data attribute on the choice cards container
        const choiceCardsContainer = document.querySelector('.choice-cards')
        if (choiceCardsContainer && choiceCardsContainer.dataset.style) {
            const style = choiceCardsContainer.dataset.style
            console.log('Returning style from data attribute:', style)
            return style
        }

        // Fallback to default white style if no data attribute is set
        console.log('No style data attribute found, returning white style')
        return 'white'
    }

    selectChoice(event) {
        console.log('selectChoice called!')
        this.updateCurrentState() // Update current state before determining style
        const card = event.currentTarget
        const choice = card.dataset.choice
        const style = this.getCardStyle()

        // Remove previous selection from all cards
        this.choiceCardTargets.forEach(c => {
            this.applyStyle(c, false, style)
            c.classList.remove('selected')
        })

        // Select new choice
        this.applyStyle(card, true, style)
        card.classList.add('selected')

        this.selectedChoice = choice

        // Handle gender description field visibility for step 10 (service seeker), step 9 (donor), and step 9 (volunteer)
        if (this.currentStep === 10 || (this.currentStep === 9 && this.getUserIntent() === 'donating') || (this.currentStep === 9 && this.getUserIntent() === 'volunteering')) {
            this.toggleGenderDescription()
        }

        // Handle city selection visibility for step 6 (donor path) and step 5 (volunteer path)
        if ((this.currentStep === 6 && this.getUserIntent() === 'donating') ||
            (this.currentStep === 5 && this.getUserIntent() === 'volunteering')) {
            this.toggleCitySelection()
        }

        this.enableNextButton()
    }

    applyStyle(card, isSelected, style) {
        switch (style) {
            case 'white':
                this.applyWhiteStyle(card, isSelected)
                break
            case 'blue':
                this.applyBlueStyle(card, isSelected)
                break
            case 'pink':
                this.applyPinkStyle(card, isSelected)
                break
            case 'seafoam':
                this.applySeafoamStyle(card, isSelected)
                break
        }
    }

    selectMultipleChoice(event) {
        this.updateCurrentState() // Update current state before determining style
        const card = event.currentTarget
        const choice = card.dataset.choice
        const style = this.getCardStyle()
        console.log('selectMultipleChoice - choice:', choice, 'style:', style, 'currentStep:', this.getCurrentStep(), 'userIntent:', this.getUserIntent())

        if (card.classList.contains('selected')) {
            // Deselect
            console.log('Deselecting card')
            this.applyStyle(card, false, style)
            card.classList.remove('selected')
            this.selectedMultipleChoices = this.selectedMultipleChoices.filter(c => c !== choice)
        } else {
            // Select
            console.log('Selecting card')
            this.applyStyle(card, true, style)
            card.classList.add('selected')
            this.selectedMultipleChoices.push(choice)
        }

        // Handle language input field visibility for step 8 (donor) and step 8 (service seeker)
        if (this.currentStep === 8 || (this.currentStep === 8 && this.getUserIntent() === 'seeking_help')) {
            this.toggleLanguageInput()
        }

        this.enableNextButton()
    }

    selectLanguage(event) {
        this.selectedChoice = event.target.value
        this.enableNextButton()
    }

    updateLanguageChoice(event) {
        this.selectedChoice = event.target.value
        this.enableNextButton()
    }

    updateGenderDescription(event) {
        this.enableNextButton()
    }

    enableNextButton() {
        const nextButton = this.nextButtonTarget
        if (nextButton) {
            if (this.hasValidSelection()) {
                nextButton.classList.remove('opacity-50', 'cursor-not-allowed')
                nextButton.classList.add('cursor-pointer')
            } else {
                nextButton.classList.add('opacity-50', 'cursor-not-allowed')
                nextButton.classList.remove('cursor-pointer')
            }
        }
    }

    hasValidSelection() {
        // Check if current step requires single or multiple choice
        const currentStep = this.getCurrentStep()
        if (this.isMultipleChoiceStep()) {
            if ((currentStep === 8 && this.selectedMultipleChoices.includes('spanish_language')) ||
                (currentStep === 8 && this.getUserIntent() === 'seeking_help' && this.selectedMultipleChoices.includes('spanish_language'))) {
                // For step 8 (donor) or step 7 (service seeker), if spanish_language is selected, also check if language input has value
                const languageInput = this.languageInputTarget
                return this.selectedMultipleChoices.length > 0 && languageInput && languageInput.value.trim() !== ''
            }
            return this.selectedMultipleChoices.length > 0
        } else if (this.isLanguageStep()) {
            // For language input step, check if there's text in the input
            const languageInput = this.languageInputTarget
            return languageInput && languageInput.value.trim() !== ''
        } else if ((currentStep === 10 || (currentStep === 9 && this.getUserIntent() === 'donating') || (currentStep === 9 && this.getUserIntent() === 'volunteering')) && this.selectedChoice === 'other') {
            // For step 10 (service seeker), step 9 (donor), or step 9 (volunteer), if "other" is selected, also check if gender description input has value
            const genderDescriptionInput = this.genderDescriptionInputTarget
            return this.selectedChoice !== null && this.selectedChoice !== '' && genderDescriptionInput && genderDescriptionInput.value.trim() !== ''
        } else if (((currentStep === 6 && this.getUserIntent() === 'donating') || (currentStep === 5 && this.getUserIntent() === 'volunteering')) && (this.selectedChoice === 'near_me' || this.selectedChoice === 'specific_location')) {
            // For step 6 (donor) or step 5 (volunteer), if location is selected, also check if city is selected
            return this.selectedChoice !== null && this.selectedChoice !== '' && this.selectedCity !== null && this.selectedCity !== ''
        } else {
            return this.selectedChoice !== null && this.selectedChoice !== ''
        }
    }

    isMultipleChoiceStep() {
        const multipleChoiceSteps = [4, 7, 8] // Service Seeker steps that allow multiple selections
        const volunteerMultipleChoiceSteps = [2, 3, 4] // Volunteer steps that allow multiple selections
        const donorMultipleChoiceSteps = [2, 5, 7] // Donor steps that allow multiple selections

        // Check based on user intent
        const userIntent = this.getUserIntent()
        const currentStep = this.getCurrentStep()
        if (userIntent === 'volunteering') {
            return volunteerMultipleChoiceSteps.includes(currentStep)
        } else if (userIntent === 'donating') {
            return donorMultipleChoiceSteps.includes(currentStep)
        } else {
            return multipleChoiceSteps.includes(currentStep)
        }
    }

    isLanguageStep() {
        return false // Language selection is now handled within step 8
    }

    nextStep(event) {
        console.log('nextStep called!')
        this.updateCurrentState() // Update current state before proceeding
        console.log('hasValidSelection:', this.hasValidSelection())
        console.log('selectedChoice:', this.selectedChoice)
        console.log('currentStep:', this.currentStep)

        // Check if this is the final step (completion step)
        const isFinalStep = this.isFinalStep()
        console.log('isFinalStep:', isFinalStep)

        if (!this.hasValidSelection() && !isFinalStep) {
            console.log('No valid selection and not final step, preventing navigation')
            event.preventDefault()
            return
        }

        // If this is the final step, navigate directly to results
        if (isFinalStep) {
            console.log('Final step detected, navigating to results')
            window.location.href = '/smart-match/results'
            return
        }

        // Prepare the answer data
        let answerData
        if (this.isMultipleChoiceStep()) {
            if ((this.currentStep === 8 && this.selectedMultipleChoices.includes('spanish_language')) ||
                (this.currentStep === 8 && this.getUserIntent() === 'seeking_help' && this.selectedMultipleChoices.includes('spanish_language'))) {
                // For step 8 (donor) or step 7 (service seeker), include both the selected choices and the language input
                const languageInput = this.languageInputTarget
                const languageValue = languageInput ? languageInput.value.trim() : ''
                answerData = {
                    choices: this.selectedMultipleChoices,
                    language: languageValue
                }
            } else {
                answerData = this.selectedMultipleChoices
            }
        } else if (this.isLanguageStep()) {
            // For language step, get the value from the input field
            const languageInput = this.languageInputTarget
            answerData = languageInput ? languageInput.value.trim() : ''
        } else if ((this.currentStep === 10 || (this.currentStep === 9 && this.getUserIntent() === 'donating') || (this.currentStep === 9 && this.getUserIntent() === 'volunteering')) && this.selectedChoice === 'other') {
            // For step 10 (service seeker), step 9 (donor), or step 9 (volunteer), if "other" is selected, include both the choice and the description
            const genderDescriptionInput = this.genderDescriptionInputTarget
            const descriptionValue = genderDescriptionInput ? genderDescriptionInput.value.trim() : ''
            answerData = {
                choice: this.selectedChoice,
                description: descriptionValue
            }
        } else if (((this.currentStep === 6 && this.getUserIntent() === 'donating') || (this.currentStep === 5 && this.getUserIntent() === 'volunteering')) && (this.selectedChoice === 'near_me' || this.selectedChoice === 'specific_location')) {
            // For step 6 (donor) or step 5 (volunteer), if location is selected, include both the choice and the city
            answerData = {
                choice: this.selectedChoice,
                city: this.selectedCity
            }
        } else {
            answerData = this.selectedChoice
        }

        console.log('answerData:', answerData)

        // Submit the choice to the current step - the controller will handle navigation
        let answerParam
        if (this.currentStep === 1) {
            // For step 1, send as simple string, not JSON
            answerParam = encodeURIComponent(answerData)
        } else {
            // For other steps, send as JSON
            answerParam = encodeURIComponent(JSON.stringify(answerData))
        }

        const url = `/smart-match/quiz?step=${this.currentStep}&answer=${answerParam}`
        console.log('Submitting answer to current step:', this.currentStep)
        console.log('Navigating to:', url)

        // Simple navigation - let the controller handle the redirect
        window.location.href = url
    }

    isFinalStep() {
        const userIntent = this.getUserIntent()
        const currentStep = this.getCurrentStep()

        // Check if this is the final step for each user intent
        if (userIntent === 'seeking_help' && currentStep === 12) {
            return true
        }
        if (userIntent === 'donating' && currentStep === 10) {
            return true
        }
        if (userIntent === 'volunteering' && currentStep === 10) {
            return true
        }

        return false
    }

    getCurrentStep() {
        const urlParams = new URLSearchParams(window.location.search)
        return parseInt(urlParams.get('step')) || 1
    }

    getUserIntent() {
        const urlParams = new URLSearchParams(window.location.search)
        return urlParams.get('intent')
    }

    toggleLanguageInput() {
        const languageInputContainer = this.languageInputContainerTarget
        const isSpanishLanguageSelected = this.selectedMultipleChoices.includes('spanish_language')

        if (isSpanishLanguageSelected) {
            languageInputContainer.classList.remove('hidden')
        } else {
            languageInputContainer.classList.add('hidden')
        }
    }

    toggleGenderDescription() {
        const genderDescriptionContainer = this.genderDescriptionContainerTarget
        const isOtherSelected = this.selectedChoice === 'other'

        if (isOtherSelected) {
            genderDescriptionContainer.classList.remove('hidden')
        } else {
            genderDescriptionContainer.classList.add('hidden')
        }
    }

    toggleMoreOptions() {
        const hiddenCards = this.hiddenCardTargets
        const moreOptionsBtn = this.moreOptionsBtnTarget

        // Check if hidden cards are currently visible
        const isShowingMore = hiddenCards.length > 0 && !hiddenCards[0].classList.contains('hidden')

        if (isShowingMore) {
            // Hide the hidden cards
            hiddenCards.forEach(card => {
                card.classList.add('hidden')
            })

            // Change button text back
            moreOptionsBtn.textContent = 'More Options'
        } else {
            // Show hidden cards
            hiddenCards.forEach(card => {
                card.classList.remove('hidden')
                // Apply the correct styling to the newly revealed card
                this.updateCurrentState()
                const style = this.getCardStyle()
                this.applyStyle(card, false, style)
            })

            // Change button text
            moreOptionsBtn.textContent = 'Show Less'
        }
    }

    toggleCitySelection() {
        const citySelectionContainer = this.citySelectionContainerTarget
        const isLocationSelected = this.selectedChoice === 'near_me' || this.selectedChoice === 'specific_location'

        if (isLocationSelected) {
            citySelectionContainer.classList.remove('hidden')
        } else {
            citySelectionContainer.classList.add('hidden')
        }
    }

    selectCity(event) {
        const cityOption = event.currentTarget
        const city = cityOption.dataset.city

        // Remove previous selection from all city options
        this.cityOptionTargets.forEach(option => {
            this.applyWhiteStyle(option, false)
            option.classList.remove('selected')
        })

        // Select new city
        this.applyWhiteStyle(cityOption, true)
        cityOption.classList.add('selected')

        this.selectedCity = city
        this.enableNextButton()
    }

    initializePreviousAnswers() {
        // Get the current step and user intent
        const currentStep = this.getCurrentStep()
        const userIntent = this.getUserIntent()

        console.log('initializePreviousAnswers - currentStep:', currentStep, 'userIntent:', userIntent)

        // Only initialize for steps after the first step
        if (currentStep > 1 && userIntent) {
            // Make an AJAX request to get the current answers from the session
            fetch(`/smart-match/current-answers?step=${currentStep}&intent=${userIntent}`, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
                .then(response => response.json())
                .then(data => {
                    console.log('Received answers data:', data)
                    if (data.answers && data.answers[currentStep]) {
                        const answer = data.answers[currentStep]
                        this.restorePreviousAnswer(answer, currentStep)
                    }
                })
                .catch(error => {
                    console.log('Could not load previous answers:', error)
                })
        }
    }

    restorePreviousAnswer(answer, step) {
        console.log('Restoring previous answer for step', step, ':', answer)

        if (Array.isArray(answer)) {
            // Multiple choice answer
            this.selectedMultipleChoices = answer
            answer.forEach(choice => {
                const card = this.element.querySelector(`[data-choice="${choice}"]`)
                if (card) {
                    const style = this.getCardStyle()
                    this.applyStyle(card, true, style)
                    card.classList.add('selected')
                }
            })

            // Handle special cases for multiple choice
            if (step === 8 && answer.includes('spanish_language')) {
                this.toggleLanguageInput()
            }
        } else {
            // Single choice answer
            this.selectedChoice = answer
            const card = this.element.querySelector(`[data-choice="${answer}"]`)
            if (card) {
                const style = this.getCardStyle()
                this.applyStyle(card, true, style)
                card.classList.add('selected')
            }

            // Handle special cases for single choice
            if (step === 10 || (step === 9 && this.getUserIntent() === 'donating') || (step === 9 && this.getUserIntent() === 'volunteering')) {
                if (answer === 'other') {
                    this.toggleGenderDescription()
                }
            }

            if ((step === 6 && this.getUserIntent() === 'donating') || (step === 5 && this.getUserIntent() === 'volunteering')) {
                if (answer === 'near_me' || answer === 'specific_location') {
                    this.toggleCitySelection()
                }
            }
        }

        this.enableNextButton()
    }

    submitFeedback(event) {
        event.preventDefault()

        const button = event.currentTarget
        const nonprofitId = button.dataset.nonprofitId
        const feedbackType = button.dataset.feedbackType

        // Disable all feedback buttons for this nonprofit to prevent double submission
        const allFeedbackButtons = document.querySelectorAll(`[data-nonprofit-id="${nonprofitId}"]`)
        allFeedbackButtons.forEach(btn => {
            btn.disabled = true
            btn.style.opacity = '0.5'
        })

        // Show loading state
        button.innerHTML = `
            <svg class="animate-spin w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span>Submitting...</span>
        `

        // Prepare recommendation data for context
        const card = button.closest('.bg-white.rounded-lg.shadow-md')
        const recommendationData = {
            nonprofit_name: card.querySelector('h3')?.textContent?.trim(),
            match_score: card.querySelector('.bg-green-500, .bg-yellow-500, .bg-orange-500, .bg-red-500')?.textContent?.trim(),
            relevance_reason: card.querySelector('.text-xs.text-gray-500')?.textContent?.trim()
        }

        // Submit feedback
        fetch('/smart-match/feedback', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
            },
            body: JSON.stringify({
                nonprofit_id: nonprofitId,
                feedback_type: feedbackType,
                recommendation_data: recommendationData
            })
        })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // Show success state
                    button.innerHTML = `
                    <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                    </svg>
                    <span>Thank you!</span>
                `

                    // Apply success styling
                    if (feedbackType === 'like') {
                        button.classList.remove('bg-gray-100', 'text-gray-700', 'hover:bg-green-100', 'hover:text-green-700')
                        button.classList.add('bg-green-100', 'text-green-700')
                    } else {
                        button.classList.remove('bg-gray-100', 'text-gray-700', 'hover:bg-red-100', 'hover:text-red-700')
                        button.classList.add('bg-red-100', 'text-red-700')
                    }

                    // Show success message
                    this.showFeedbackMessage('Thank you for your feedback!', 'success')
                } else {
                    // Show error state
                    this.showFeedbackMessage(data.error || 'Failed to submit feedback', 'error')

                    // Re-enable buttons
                    allFeedbackButtons.forEach(btn => {
                        btn.disabled = false
                        btn.style.opacity = '1'
                    })

                    // Reset button content
                    this.resetFeedbackButton(button, feedbackType)
                }
            })
            .catch(error => {
                console.error('Feedback submission error:', error)
                this.showFeedbackMessage('Failed to submit feedback. Please try again.', 'error')

                // Re-enable buttons
                allFeedbackButtons.forEach(btn => {
                    btn.disabled = false
                    btn.style.opacity = '1'
                })

                // Reset button content
                this.resetFeedbackButton(button, feedbackType)
            })
    }

    resetFeedbackButton(button, feedbackType) {
        if (feedbackType === 'like') {
            button.innerHTML = `
                <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5"></path>
                </svg>
                <span>Like</span>
            `
        } else {
            button.innerHTML = `
                <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14H5.236a2 2 0 01-1.789-2.894l3.5-7A2 2 0 018.736 3h4.018c.163 0 .326.02.485.06L17 4m-7 10v5a2 2 0 002 2h.095c.5 0 .905-.405.905-.905 0-.714.211-1.412.608-2.006L17 13V4m-7 10h2M17 4h2a2 2 0 012 2v6a2 2 0 01-2 2h-2.5"></path>
                </svg>
                <span>Dislike</span>
            `
        }
    }

    showFeedbackMessage(message, type) {
        // Remove any existing message
        const existingMessage = document.querySelector('.feedback-message')
        if (existingMessage) {
            existingMessage.remove()
        }

        // Create new message
        const messageDiv = document.createElement('div')
        messageDiv.className = `feedback-message fixed top-4 right-4 z-50 px-4 py-2 rounded-md shadow-lg transition-all duration-300 ${type === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
            }`
        messageDiv.textContent = message

        // Add to page
        document.body.appendChild(messageDiv)

        // Remove after 3 seconds
        setTimeout(() => {
            messageDiv.style.opacity = '0'
            setTimeout(() => {
                if (messageDiv.parentNode) {
                    messageDiv.parentNode.removeChild(messageDiv)
                }
            }, 300)
        }, 3000)
    }
} 