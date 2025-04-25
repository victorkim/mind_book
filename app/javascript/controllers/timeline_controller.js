// app/javascript/controllers/timeline_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Initial setup
    this.isCommentsTimeline = this.element.classList.contains('comments-timeline');
    this.isProjectsTimeline = !this.isCommentsTimeline;
    
    // References to important elements
    this.contentElement = this.element.querySelector('.gantt-timeline-content');
    this.verticalLines = this.element.querySelectorAll('.vertical-line');
    this.currentWeekColumns = this.element.querySelectorAll('.current-week-column');
    this.projectBars = this.element.querySelectorAll('.project-bar-container');
    this.header = this.element.querySelector('.gantt-timeline-header');
    this.chartAreas = this.element.querySelectorAll('.gantt-chart-area');
    this.projectRows = this.element.querySelectorAll('.gantt-project-row');
    
    // Set up event handlers with proper binding
    this.resizeHandler = this.handleResize.bind(this);
    this.scrollHandler = this.handleScroll.bind(this);
    
    // Add event listeners
    window.addEventListener('resize', this.resizeHandler);
    this.element.addEventListener('scroll', this.scrollHandler);
    
    // Initial adjustments
    this.adjustTimeline();
    
    // Run again after content is fully loaded
    setTimeout(() => {
      this.adjustTimeline();
      this.adjustWidths(); // New method to set proper widths
      this.adjustCurrentWeekColumn();
      
      // Set initial scroll position for projects timeline
      if (this.isProjectsTimeline && this.element.closest('#projects_timeline')) {
        this.scrollToRelevantWeek();
      }
    }, 200);
  }
  
  disconnect() {
    // Clean up event listeners on disconnect
    window.removeEventListener('resize', this.resizeHandler);
    this.element.removeEventListener('scroll', this.scrollHandler);
  }
  
  handleResize() {
    this.adjustTimeline();
    this.adjustWidths(); // Add width adjustment on resize
    this.adjustCurrentWeekColumn();
  }
  
  handleScroll() {
    // We don't need to do anything special on scroll now
    // The CSS will handle hiding overflowing content
  }
  
  // New method to set widths properly based on number of date headers
  adjustWidths() {
    const dateHeaders = this.element.querySelectorAll('.gantt-date-header');
    if (dateHeaders.length === 0) return;
    
    // Calculate the total width based on number of week columns
    // Each column has a width of var(--week-width) which is 80px by default
    const totalWeekWidth = dateHeaders.length * 80;
    
    // Get the info column width
    const infoColumn = this.element.querySelector('.gantt-info-column');
    const infoColumnWidth = infoColumn ? infoColumn.offsetWidth : 0;
    
    // Set width on chart areas (apply to all of them)
    this.chartAreas.forEach(chartArea => {
      chartArea.style.width = `${totalWeekWidth}px`;
      chartArea.style.minWidth = `${totalWeekWidth}px`;
    });
    
    // Set width on the timeline header
    if (this.header) {
      // The header already includes the info column, so set the width to total
      const totalWidth = totalWeekWidth + infoColumnWidth;
      this.header.style.width = `${totalWidth}px`;
      this.header.style.minWidth = `${totalWidth}px`;
    }
    
    // Set width on the content element
    if (this.contentElement) {
      const totalWidth = totalWeekWidth + infoColumnWidth;
      this.contentElement.style.width = `${totalWidth}px`;
      this.contentElement.style.minWidth = `${totalWidth}px`;
    }
  }
  
  adjustTimeline() {
    // Calculate appropriate heights for timeline elements
    const headerHeight = this.header ? this.header.offsetHeight : 0;
    let height;
    
    if (this.isCommentsTimeline) {
      // For comments timeline, use container height
      const containerHeight = this.element.clientHeight;
      height = containerHeight - headerHeight + 20; // Add padding
    } else {
      // For projects timeline, calculate based on content
      this.adjustSeparatorWidths();
      
      const lastProjectRow = this.element.querySelector('.gantt-project-row.last-project');
      if (lastProjectRow) {
        const lastProjectBottom = lastProjectRow.offsetTop + lastProjectRow.offsetHeight;
        height = lastProjectBottom + 30; // Add padding
        
        // Adjust content element height for projects timeline
        if (this.contentElement) {
          this.contentElement.style.minHeight = `${height}px`;
          this.contentElement.style.height = `${height}px`;
        }
      } else {
        height = 200; // Default fallback height
      }
    }
    
    // Apply the calculated height to vertical lines
    this.setElementsHeight(this.verticalLines, height);
  }
  
  adjustSeparatorWidths() {
    if (!this.isProjectsTimeline) return;
    
    // Calculate total width of timeline
    const dateHeaders = this.element.querySelectorAll('.gantt-date-header');
    if (dateHeaders.length === 0) return;
    
    // Each header is var(--week-width) wide (80px by default)
    const totalWidth = dateHeaders.length * 80;
    
    // Add the info column width
    const infoColumn = this.element.querySelector('.gantt-info-column');
    const infoColumnWidth = infoColumn ? infoColumn.offsetWidth : 0;
    
    // Apply width to separators
    const fullWidth = `${totalWidth + infoColumnWidth}px`;
    const separators = this.element.querySelectorAll('.gantt-separator');
    separators.forEach(separator => {
      separator.style.width = fullWidth;
      separator.style.minWidth = fullWidth;
    });
  }
  
  adjustCurrentWeekColumn() {
    if (!this.currentWeekColumns || this.currentWeekColumns.length === 0) return;
    
    // Calculate appropriate height for current week column (same logic as vertical lines)
    const headerHeight = this.header ? this.header.offsetHeight : 0;
    let height;
    
    if (this.isCommentsTimeline) {
      height = this.element.clientHeight - headerHeight + 20;
    } else {
      const lastProjectRow = this.element.querySelector('.gantt-project-row.last-project');
      height = lastProjectRow ? 
        lastProjectRow.offsetTop + lastProjectRow.offsetHeight + 30 : 
        200;
    }
    
    // Apply the calculated height to current week columns
    this.setElementsHeight(this.currentWeekColumns, height);
  }
  
  setElementsHeight(elements, height) {
    if (!elements || elements.length === 0) return;
    
    elements.forEach(element => {
      if (!element) return;
      element.style.height = `${height}px`;
    });
  }
  
  // Method to scroll to 8 weeks before current week
  scrollToRelevantWeek() {
    // Find the current week column
    const currentWeekColumn = this.element.querySelector('.current-week-column');
    if (!currentWeekColumn) return;
    
    // Find the parent date header
    const currentDateHeader = currentWeekColumn.closest('.gantt-date-header');
    if (!currentDateHeader) return;
    
    // Get all date headers to determine the index
    const allDateHeaders = Array.from(this.element.querySelectorAll('.gantt-date-header'));
    const currentIndex = allDateHeaders.indexOf(currentDateHeader);
    
    if (currentIndex === -1) return;
    
    // Calculate the target index (8 weeks before current)
    const targetIndex = Math.max(0, currentIndex - 8);
    
    // Calculate the scroll position
    // Each week is 80px wide (from CSS var(--week-width))
    const scrollLeft = targetIndex * 80;
    
    // Scroll to the position
    this.element.scrollLeft = Math.max(0, scrollLeft);
  }
}