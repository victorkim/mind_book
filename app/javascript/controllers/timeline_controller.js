// app/javascript/controllers/timeline_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Initial setup
    this.isCommentsTimeline = this.element.classList.contains('comments-timeline');
    this.isProjectsTimeline = this.element.classList.contains('projects-timeline') || !this.isCommentsTimeline;
    
    // References to important elements
    this.contentElement = this.element.querySelector('.gantt-timeline-content');
    this.verticalLines = this.element.querySelectorAll('.vertical-line');
    
    // Initial calculation
    this.adjustTimeline();
    
    // Set up event handlers with proper binding
    this.resizeHandler = this.handleResize.bind(this);
    this.scrollHandler = this.handleScroll.bind(this);
    
    // Add event listeners
    window.addEventListener('resize', this.resizeHandler);
    
    // For projects timeline with scrolling content
    if (this.isProjectsTimeline) {
      this.element.addEventListener('scroll', this.scrollHandler);
      
      // Also adjust separator widths for projects timeline
      this.adjustSeparatorWidths();
      
      // Run again after content is fully loaded
      setTimeout(() => {
        this.adjustTimeline();
        this.adjustSeparatorWidths();
      }, 200);
    }
  }
  
  disconnect() {
    // Clean up event listeners on disconnect
    window.removeEventListener('resize', this.resizeHandler);
    this.element.removeEventListener('scroll', this.scrollHandler);
  }
  
  handleResize() {
    this.adjustTimeline();
    if (this.isProjectsTimeline) {
      this.adjustSeparatorWidths();
    }
  }
  
  handleScroll() {
    // Only needed for projects timeline
    if (this.isProjectsTimeline) {
      this.adjustTimeline();
    }
  }
  
  adjustSeparatorWidths() {
    if (!this.isProjectsTimeline) return;
    
    // Calculate total width of all date headers
    const dateHeaders = this.element.querySelectorAll('.gantt-date-header');
    if (dateHeaders.length === 0) return;
    
    // Each header is var(--week-width) wide (80px by default)
    const totalWidth = dateHeaders.length * 80;
    
    // Add the info column width
    const infoColumn = this.element.querySelector('.gantt-info-column');
    const infoColumnWidth = infoColumn ? infoColumn.offsetWidth : 0;
    
    // Set width for all separators
    const separators = this.element.querySelectorAll('.gantt-separator');
    separators.forEach(separator => {
      separator.style.width = `${totalWidth + infoColumnWidth}px`;
      separator.style.minWidth = `${totalWidth + infoColumnWidth}px`;
    });
  }
  
  adjustTimeline() {
    // Get precise measurements of content
    const content = this.contentElement;
    
    if (this.isCommentsTimeline) {
      // Simpler calculation for comments timeline
      const height = content.offsetHeight + 20;
      this.setVerticalLinesHeight(height);
    } else {
      // For projects timeline, calculate precisely based on content
      this.adjustProjectsTimeline();
    }
  }
  
  adjustProjectsTimeline() {
    // Find all the elements we need to measure
    const departments = this.element.querySelectorAll('.gantt-department-header');
    const projectRows = this.element.querySelectorAll('.gantt-project-row');
    const separators = this.element.querySelectorAll('.gantt-separator');
    
    // Find the last project row to calculate the exact bottom position
    if (projectRows.length > 0) {
      const lastProjectRow = projectRows[projectRows.length - 1];
      
      // Calculate the position of the bottom of the last project row
      const headerHeight = this.element.querySelector('.gantt-timeline-header').offsetHeight;
      const lastProjectBottom = lastProjectRow.offsetTop + lastProjectRow.offsetHeight;
      
      // Set lines to reach just beyond the last project row
      this.setVerticalLinesHeight(lastProjectBottom + 10);
      
      // Also adjust container height to match content exactly
      if (this.isProjectsTimeline) {
        // Let container size to content with a small buffer
        const containerHeight = lastProjectBottom + 30;
        this.contentElement.style.minHeight = `${containerHeight}px`;
        this.contentElement.style.maxHeight = `${containerHeight}px`;
      }
    } else {
      // Fallback if no projects found
      this.setVerticalLinesHeight(200);
    }
  }
  
  setVerticalLinesHeight(height) {
    this.verticalLines.forEach(line => {
      // Set the calculated height
      line.style.height = `${height}px`;
      
      // Ensure other critical styles
      line.style.position = 'absolute';
      line.style.width = '1px';
      line.style.backgroundColor = '#ddd';
      line.style.zIndex = '1';
      line.style.top = '30px';
      line.style.right = '0';
      line.style.pointerEvents = 'none';
    });
  }
}