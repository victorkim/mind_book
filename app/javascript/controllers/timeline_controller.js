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
      this.adjustCurrentWeekColumn();
    }, 200);
  }
  
  disconnect() {
    // Clean up event listeners on disconnect
    window.removeEventListener('resize', this.resizeHandler);
    this.element.removeEventListener('scroll', this.scrollHandler);
  }
  
  handleResize() {
    this.adjustTimeline();
    this.adjustCurrentWeekColumn();
  }
  
  handleScroll() {
    this.adjustTimeline();
    this.adjustCurrentWeekColumn();
  }
  
  adjustTimeline() {
    // Calculate appropriate heights for timeline elements
    const headerHeight = this.element.querySelector('.gantt-timeline-header').offsetHeight;
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
        this.contentElement.style.minHeight = `${height}px`;
        this.contentElement.style.maxHeight = `${height}px`;
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
    if (this.currentWeekColumns.length === 0) return;
    
    // Calculate appropriate height for current week column (same logic as vertical lines)
    const headerHeight = this.element.querySelector('.gantt-timeline-header').offsetHeight;
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
    elements.forEach(element => {
      element.style.height = `${height}px`;
      
      // For vertical lines, ensure other critical styles
      if (element.classList.contains('vertical-line')) {
        element.style.position = 'absolute';
        element.style.width = '1px';
        element.style.backgroundColor = '#ddd';
        element.style.zIndex = '1';
        element.style.top = '30px';
        element.style.right = '0';
        element.style.pointerEvents = 'none';
      }
    });
  }
}