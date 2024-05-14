import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ['output'];

  connect() {
    this.poll();
  }

  poll() {
    setInterval(() => {
      fetch('/close_encounters')
        .then(response => response.json())
        .then(data => {
          this.outputTarget.textContent = data;
        })
        .catch(error => {
          console.error('Error:', error);
        });
    }, 30000); // Poll every 30 seconds
  }
}