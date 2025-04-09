/**
 * Mobile Menu Compatibility Fix
 * This utility helps ensure that the mobile menu works correctly across all devices
 */

// Function to be called when the mobile menu opens
export const fixMobileMenuOnOpen = () => {
  const panel = document.querySelector('.mobile-menu-panel');
  const backdrop = document.querySelector('.mobile-menu-backdrop');
  const menuContent = document.querySelector('.mobile-menu-panel .menu-content');
  
  if (panel) {
    // Force panel visibility and position
    panel.style.display = 'flex';
    panel.style.visibility = 'visible';
    panel.style.opacity = '1';
    panel.style.transform = 'translateX(0)';
    
    // Disable scrolling on the body when menu is open
    document.body.style.overflow = 'hidden';
    
    // Fix for iOS height issues
    if (/iPhone|iPad|iPod/.test(navigator.userAgent)) {
      panel.style.height = `${window.innerHeight}px`;
    }
  }
  
  // Force menu content visibility
  if (menuContent) {
    menuContent.style.display = 'flex';
    menuContent.style.visibility = 'visible';
    menuContent.style.opacity = '1';
    
    // Force all child elements to be visible
    const allMenuItems = menuContent.querySelectorAll('*');
    allMenuItems.forEach(el => {
      el.style.visibility = 'visible';
      el.style.opacity = '1';
      if (el.tagName !== 'SVG' && el.tagName !== 'path') {
        if (el.classList.contains('menu-item')) {
          el.style.display = 'flex';
        } else if (el.tagName === 'SPAN') {
          el.style.display = 'inline';
        } else {
          el.style.display = 'block';
        }
      }
    });
  }
  
  if (backdrop) {
    backdrop.style.display = 'block';
    backdrop.style.opacity = '1';
  }
  
  // Force all menu items to be visible
  const menuItems = document.querySelectorAll('.menu-item');
  menuItems.forEach(item => {
    item.style.visibility = 'visible';
    item.style.opacity = '1';
    item.style.display = 'flex';
  });
  
  // Call additional enhancement functions
  enhanceSubmenuButtons();
  enhanceMenuContent();
  
  console.log('Mobile menu fix applied - menu opened');
};

// Enhance all technical submenu buttons
export const enhanceSubmenuButtons = () => {
  // Target specific submenu buttons in the technical section
  const buttons = document.querySelectorAll('.mobile-submenu button');
  
  buttons.forEach(button => {
    // Force visibility and styling
    button.style.display = 'block';
    button.style.width = '100%';
    button.style.textAlign = 'left';
    button.style.padding = '0.5rem 0.75rem';
    button.style.fontSize = '0.875rem';
    button.style.visibility = 'visible';
    button.style.opacity = '1';
    button.style.pointerEvents = 'auto';
    button.style.zIndex = '10005';
    
    // Add a red hover effect
    button.addEventListener('mouseover', () => {
      button.style.backgroundColor = 'rgba(239, 68, 68, 0.15)';
    });
    
    button.addEventListener('mouseout', () => {
      button.style.backgroundColor = 'transparent';
    });
  });
};

// Function to fix technical submenu content
export const enhanceMenuContent = () => {
  // Force better styling for menu content
  const menuItem = document.querySelector('.mobile-menu-panel .menu-content');
  if (menuItem) {
    // Add !important styles with direct DOM manipulation
    const style = document.createElement('style');
    style.textContent = `
      .mobile-menu-panel, 
      .mobile-menu-panel .menu-content,
      .mobile-menu-panel .menu-item,
      .mobile-menu-panel .mobile-submenu,
      .mobile-menu-panel button,
      .mobile-menu-panel a,
      .mobile-menu-panel div,
      .mobile-menu-panel svg,
      .mobile-menu-panel span {
        display: block !important;
        visibility: visible !important;
        opacity: 1 !important;
        color: #f1f1f1 !important;
      }
      
      .mobile-menu-panel .menu-item {
        display: flex !important;
      }
      
      .mobile-menu-panel span {
        display: inline !important;
      }
      
      .mobile-menu-panel.show {
        transform: translateX(0) !important;
      }
    `;
    document.head.appendChild(style);
  }
};

// Function to be called when the mobile menu closes
export const fixMobileMenuOnClose = () => {
  const panel = document.querySelector('.mobile-menu-panel');
  const backdrop = document.querySelector('.mobile-menu-backdrop');
  
  if (panel) {
    panel.style.transform = 'translateX(100%)';
    
    // Re-enable scrolling on body
    document.body.style.overflow = '';
  }
  
  if (backdrop) {
    backdrop.style.opacity = '0';
    
    // Hide backdrop after transition
    setTimeout(() => {
      if (backdrop) backdrop.style.display = 'none';
    }, 300);
  }
  
  console.log('Mobile menu fix applied - menu closed');
};

// Function to fix mobile submenu display issues
export const fixTechnicalSubmenu = (isOpen) => {
  const submenu = document.querySelector('.mobile-submenu');
  
  if (submenu) {
    if (isOpen) {
      submenu.style.display = 'block';
      submenu.style.maxHeight = '500px';
      submenu.style.visibility = 'visible';
      submenu.style.opacity = '1';
      submenu.classList.add('visible');
      submenu.classList.remove('hidden');
      
      // Apply enhanced styling to all buttons in the submenu
      enhanceSubmenuButtons();
    } else {
      submenu.style.maxHeight = '0';
      submenu.style.visibility = 'hidden';
      submenu.style.opacity = '0';
      
      // Hide after transition
      setTimeout(() => {
        if (!isOpen) {
          submenu.style.display = 'none';
          submenu.classList.add('hidden');
          submenu.classList.remove('visible');
        }
      }, 300);
    }
  }
};

// Fix for initial page load
export const initMobileMenuFix = () => {
  // Check if we're on a mobile device
  const isMobile = window.innerWidth < 768;
  
  if (isMobile) {
    // Ensure menu is properly hidden at start
    const panel = document.querySelector('.mobile-menu-panel');
    if (panel) {
      panel.style.transform = 'translateX(100%)';
    }
    
    // Listen for orientation changes
    window.addEventListener('orientationchange', () => {
      setTimeout(() => {
        const currentPanel = document.querySelector('.mobile-menu-panel');
        if (currentPanel && currentPanel.classList.contains('show')) {
          // If menu is open, make sure it fills the new orientation height
          currentPanel.style.height = `${window.innerHeight}px`;
        }
      }, 300);
    });
  }
  
  console.log('Mobile menu fixes initialized');
  
  // Return cleanup function
  return () => {
    window.removeEventListener('orientationchange', () => {});
  };
};

export default {
  fixMobileMenuOnOpen,
  fixMobileMenuOnClose,
  fixTechnicalSubmenu,
  initMobileMenuFix,
  enhanceSubmenuButtons,
  enhanceMenuContent
};