// Core Application State & UI Controller
const app = {
  currentTab: 'dashboard',

  init() {
    this.setupNavigation();
    this.setupClock();
    this.setupShortcuts();
    this.setupSidebarToggle();

    // Check URL hash for initial tab
    const hash = window.location.hash.replace('#', '');
    if (hash && document.getElementById(`tab-${hash}`)) {
      this.switchTab(hash);
    } else {
      this.switchTab('dashboard');
    }
  },

  // Setup tab navigation
  setupNavigation() {
    document.querySelectorAll('.sidebar-nav .nav-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        const tab = item.getAttribute('data-tab');
        if (tab) this.switchTab(tab);
      });
    });

    // Quick POS buttons
    document.getElementById('topbar-quick-pos')?.addEventListener('click', () => {
      this.switchTab('pos');
    });

    document.getElementById('topbar-lowstock-btn')?.addEventListener('click', () => {
      this.switchTab('inventory');
      const filterStatus = document.getElementById('filter-inventory-status');
      if (filterStatus) {
        filterStatus.value = 'low';
        inventoryModule.loadInventory();
      }
    });
  },

  // Switch between tabs
  switchTab(tabId) {
    this.currentTab = tabId;
    window.location.hash = tabId;

    // Update active nav item
    document.querySelectorAll('.sidebar-nav .nav-item').forEach(item => {
      item.classList.toggle('active', item.getAttribute('data-tab') === tabId);
    });

    // Update active pane
    document.querySelectorAll('.tab-pane').forEach(pane => {
      pane.classList.toggle('active', pane.id === `tab-${tabId}`);
    });

    // Update page title
    const titles = {
      dashboard: 'Tổng quan & Thống kê',
      pos: 'Quầy Thu Ngân (Bán Hàng)',
      products: 'Quản lý Sản phẩm',
      categories: 'Quản lý Loại sản phẩm',
      inventory: 'Kho hàng & Kiểm kê',
      invoices: 'Lịch sử Hóa đơn bán hàng',
      receipts: 'Quản lý Phiếu nhập hàng',
      customers: 'Quản lý Khách hàng',
      suppliers: 'Quản lý Nhà cung cấp',
      employees: 'Quản lý Nhân viên',
      reports: 'Báo cáo & Phân tích kinh doanh'
    };
    const titleEl = document.getElementById('page-title');
    if (titleEl) titleEl.textContent = titles[tabId] || 'Hệ Thống Quản Lý Tạp Hóa';

    // On mobile, close sidebar after clicking
    if (window.innerWidth <= 768) {
      document.querySelector('.sidebar')?.classList.remove('open');
    }

    // Trigger tab-specific loader
    this.loadTabData(tabId);
  },

  // Load relevant data for the tab
  loadTabData(tabId) {
    switch (tabId) {
      case 'dashboard':
        dashboardModule.loadDashboard();
        break;
      case 'pos':
        posModule.loadPOS();
        break;
      case 'products':
        productsModule.loadProducts();
        productsModule.loadFilterCategories();
        break;
      case 'categories':
        categoriesModule.loadCategories();
        break;
      case 'inventory':
        inventoryModule.loadInventory();
        break;
      case 'invoices':
        invoicesModule.loadInvoices();
        break;
      case 'receipts':
        receiptsModule.loadReceipts();
        break;
      case 'customers':
        customersModule.loadCustomers();
        break;
      case 'suppliers':
        suppliersModule.loadSuppliers();
        break;
      case 'employees':
        employeesModule.loadEmployees();
        break;
      case 'reports':
        reportsModule.loadReports();
        break;
    }
  },

  // Realtime clock
  setupClock() {
    const clockEl = document.getElementById('live-clock');
    if (!clockEl) return;
    const dateEl = clockEl.querySelector('.clock-date');
    const timeEl = clockEl.querySelector('.clock-time');

    const updateTime = () => {
      const now = new Date();
      const d = String(now.getDate()).padStart(2, '0');
      const m = String(now.getMonth() + 1).padStart(2, '0');
      const y = now.getFullYear();
      const hh = String(now.getHours()).padStart(2, '0');
      const mm = String(now.getMinutes()).padStart(2, '0');
      const ss = String(now.getSeconds()).padStart(2, '0');

      if (dateEl) dateEl.textContent = `${d}/${m}/${y}`;
      if (timeEl) timeEl.textContent = `${hh}:${mm}:${ss}`;
    };

    updateTime();
    setInterval(updateTime, 1000);
  },

  // Global Keyboard shortcuts (F2 to open POS)
  setupShortcuts() {
    document.addEventListener('keydown', (e) => {
      if (e.key === 'F2') {
        e.preventDefault();
        this.switchTab('pos');
        document.getElementById('pos-search-input')?.focus();
      }
    });
  },

  // Sidebar toggle on mobile
  setupSidebarToggle() {
    const toggleBtn = document.getElementById('sidebar-toggle');
    const sidebar = document.querySelector('.sidebar');
    if (toggleBtn && sidebar) {
      toggleBtn.addEventListener('click', () => {
        sidebar.classList.toggle('open');
      });
    }
  },

  // Modal helpers
  openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.add('active');
    }
  },

  closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.remove('active');
    }
  },

  // Toast notifications
  showToast(message, type = 'success', duration = 3000) {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    const icons = {
      success: '✅',
      error: '❌',
      warning: '⚠️',
      info: 'ℹ️'
    };

    toast.innerHTML = `
      <span class="toast-icon">${icons[type] || 'ℹ️'}</span>
      <span class="toast-message">${message}</span>
    `;

    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateX(100%)';
      setTimeout(() => toast.remove(), 300);
    }, duration);
  },

  // Format currency: 15000 -> 15.000 ₫
  formatCurrency(amount) {
    if (amount === undefined || amount === null) return '0 ₫';
    return Number(amount).toLocaleString('vi-VN') + ' ₫';
  },

  // Format date time: 2026-11-05 21:30:00 -> 21:30 05/11/2026
  formatDateTime(dateStr) {
    if (!dateStr) return '--';
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const year = d.getFullYear();
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');
    return `${hours}:${minutes} ${day}/${month}/${year}`;
  },

  formatDate(dateStr) {
    if (!dateStr) return '--';
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const year = d.getFullYear();
    return `${day}/${month}/${year}`;
  }
};

window.addEventListener('DOMContentLoaded', () => {
  app.init();
});
