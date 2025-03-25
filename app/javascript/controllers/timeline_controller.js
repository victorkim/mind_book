// app/javascript/controllers/timeline_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Initialize timeline dimensions and settings
    this.initializeTimeline();
    
    // Add scroll event listener for horizontal scrolling
    this.addScrollListeners();
    
    // Ensure this runs after the DOM is fully loaded
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.refreshLayout());
    } else {
      this.refreshLayout();
    }
  }
  
  initializeTimeline() {
    // Get all week headers and calculate total width
    const dateHeaders = document.querySelectorAll('.gantt-date-header');
    const weekWidth = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--week-width') || '80');
    const infoColumnWidth = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--info-column-width') || '250');
    
    if (dateHeaders.length > 0) {
      // Calculate total width needed for the timeline
      const totalWeekWidth = dateHeaders.length * weekWidth;
      const totalWidth = totalWeekWidth + infoColumnWidth;
      
      // Set CSS variable for total width - critical for fixed positioning
      document.documentElement.style.setProperty('--total-timeline-width', totalWeekWidth + 'px');
      
      // Set fixed width for chart areas
      const chartAreas = document.querySelectorAll('.gantt-chart-area');
      chartAreas.forEach(area => {
        area.style.width = totalWeekWidth + 'px';
      });
      
      // Ensure top separator spans the entire width
      const topSeparator = document.querySelector('.timeline-top-separator');
      if (topSeparator) {
        topSeparator.style.width = totalWeekWidth + 'px';
      }
      
      // Ensure all department separators span the entire width
      const separators = document.querySelectorAll('.gantt-separator');
      separators.forEach(separator => {
        separator.style.width = totalWidth + 'px';
      });
      
      // Fix the heights of the vertical lines to match content height
      const contentHeight = document.querySelector('.gantt-timeline-content').offsetHeight;
      const verticalLines = document.querySelectorAll('.vertical-line');
      verticalLines.forEach(line => {
        line.style.height = contentHeight + 'px';
      });
    }
  }
  
  addScrollListeners() {
    const container = document.querySelector('.gantt-timeline-container');
    const infoColumnWidth = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--info-column-width') || '250');
    
    if (container) {
      container.addEventListener('scroll', () => {
        const scrollLeft = container.scrollLeft;
        
        // Handle vertical lines visibility
        const verticalLines = document.querySelectorAll('.vertical-line');
        verticalLines.forEach(line => {
          const headerRect = line.parentElement.getBoundingClientRect();
          const containerRect = container.getBoundingClientRect();
          
          // Hide vertical lines that are scrolled off to the left
          if (headerRect.right <= containerRect.left + infoColumnWidth) {
            line.style.visibility = 'hidden';
          } else {
            line.style.visibility = 'visible';
          }
        });
      });
    }
  }
  
  refreshLayout() {
    // Force recalculation of dimensions after DOM is fully loaded
    setTimeout(() => {
      this.initializeTimeline();
    }, 100);
  }
}