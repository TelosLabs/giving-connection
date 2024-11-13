import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fadeInElement"];

  connect() {
    this.observer = new IntersectionObserver(this.handleIntersect.bind(this), {
      threshold: 0.1
    });

    this.fadeInElementTargets.forEach(element => {
      this.observer.observe(element);
    });
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const delay = entry.target.dataset.delay || 0; // Default to 0 if no delay is specified
        entry.target.style.transitionDelay = `${delay}ms`;
        entry.target.classList.add('opacity-100', 'transition-opacity', 'duration-1000');
        this.observer.unobserve(entry.target);
      }
    });
  }
}