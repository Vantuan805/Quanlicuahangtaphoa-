// POS (Point of Sale / Thu Ngân Bán Hàng) Module
const posModule = {
  products: [],
  categories: [],
  customers: [],
  employees: [],
  cart: [],
  activeCategory: 'all',
  searchQuery: '',

  async loadPOS() {
    try {
      await Promise.all([
        this.fetchProducts(),
        this.fetchCategories(),
        this.fetchCustomers(),
        this.fetchEmployees()
      ]);
      this.initEvents();
      this.renderCategories();
      this.renderProducts();
      this.renderCart();
    } catch (err) {
      console.error('POS load error:', err);
    }
  },

  async fetchProducts() {
    const res = await api.get('/api/products');
    if (res.success) {
      this.products = res.data;
    }
  },

  async fetchCategories() {
    const res = await api.get('/api/categories');
    if (res.success) {
      this.categories = res.data;
    }
  },

  async fetchCustomers() {
    const res = await api.get('/api/customers');
    if (res.success) {
      this.customers = res.data;
      const select = document.getElementById('pos-customer-select');
      if (select) {
        select.innerHTML = '<option value="">Khách vãng lai (Lẻ)</option>' +
          this.customers.map(c => `
            <option value="${c.id}" data-points="${c.points || 0}" data-spent="${c.total_spent || 0}">
              ${c.name} (${c.phone || 'Không SĐT'}) - ${c.points || 0} điểm
            </option>
          `).join('');
      }
    }
  },

  async fetchEmployees() {
    const res = await api.get('/api/employees');
    if (res.success) {
      this.employees = res.data.filter(e => e.status === 'active');
      const select = document.getElementById('pos-employee-select');
      if (select) {
        select.innerHTML = this.employees.map(e => `
          <option value="${e.id}">${e.name} (${e.role})</option>
        `).join('');
      }
    }
  },

  initEvents() {
    if (this._eventsInitialized) return;
    this._eventsInitialized = true;

    // Search input
    const searchInput = document.getElementById('pos-search-input');
    const searchClear = document.getElementById('pos-search-clear');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        this.searchQuery = e.target.value.trim().toLowerCase();
        if (searchClear) searchClear.style.display = this.searchQuery ? 'block' : 'none';
        this.renderProducts();
      });

      // Barcode Enter key: if exact match, add immediately
      searchInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          const query = this.searchQuery;
          if (!query) return;

          const exactMatch = this.products.find(p => 
            p.barcode === query || p.code.toLowerCase() === query || p.name.toLowerCase() === query
          );

          if (exactMatch) {
            this.addToCart(exactMatch.id);
            searchInput.value = '';
            this.searchQuery = '';
            if (searchClear) searchClear.style.display = 'none';
            this.renderProducts();
          }
        }
      });
    }

    if (searchClear) {
      searchClear.addEventListener('click', () => {
        if (searchInput) searchInput.value = '';
        this.searchQuery = '';
        searchClear.style.display = 'none';
        this.renderProducts();
      });
    }

    // Customer change
    const custSelect = document.getElementById('pos-customer-select');
    if (custSelect) {
      custSelect.addEventListener('change', () => {
        const opt = custSelect.options[custSelect.selectedIndex];
        const infoPill = document.getElementById('pos-customer-info');
        if (custSelect.value) {
          const points = opt.getAttribute('data-points') || 0;
          const spent = opt.getAttribute('data-spent') || 0;
          document.getElementById('pos-cust-points').textContent = points;
          document.getElementById('pos-cust-spent').textContent = app.formatCurrency(spent);
          if (infoPill) infoPill.style.display = 'inline-block';
        } else {
          if (infoPill) infoPill.style.display = 'none';
        }
      });
    }

    // Quick add customer from POS
    document.getElementById('pos-add-customer-btn')?.addEventListener('click', () => {
      document.getElementById('form-customer')?.reset();
      document.getElementById('cust-id').value = '';
      document.getElementById('modal-customer-title').textContent = 'Thêm khách hàng mới';
      app.openModal('modal-customer');
    });

    // Clear cart
    document.getElementById('cart-clear-btn')?.addEventListener('click', () => {
      if (this.cart.length === 0) return;
      if (confirm('Bạn có chắc muốn xóa tất cả sản phẩm trong giỏ hàng?')) {
        this.cart = [];
        this.renderCart();
      }
    });

    // Discount change
    document.getElementById('cart-discount-input')?.addEventListener('input', () => {
      this.updateCalculations();
    });

    // Customer Payment input
    document.getElementById('cart-customer-payment')?.addEventListener('input', () => {
      this.updateCalculations();
    });

    // Quick cash buttons
    document.querySelectorAll('.btn-cash').forEach(btn => {
      btn.addEventListener('click', () => {
        const val = btn.getAttribute('data-cash');
        const payInput = document.getElementById('cart-customer-payment');
        const total = this.calculateTotal();

        if (val === 'exact') {
          if (payInput) payInput.value = total;
        } else {
          const num = Number(val);
          if (payInput) payInput.value = num;
        }
        this.updateCalculations();
      });
    });

    // Checkout button
    document.getElementById('btn-process-checkout')?.addEventListener('click', () => {
      this.processCheckout();
    });
  },

  renderCategories() {
    const container = document.getElementById('pos-category-chips');
    if (!container) return;

    let html = `<button class="chip ${this.activeCategory === 'all' ? 'active' : ''}" data-cat-id="all">Tất cả (${this.products.length})</button>`;

    this.categories.forEach(c => {
      const count = this.products.filter(p => p.category_id === c.id).length;
      html += `
        <button class="chip ${this.activeCategory == c.id ? 'active' : ''}" data-cat-id="${c.id}">
          ${c.name} (${count})
        </button>
      `;
    });

    container.innerHTML = html;

    container.querySelectorAll('.chip').forEach(btn => {
      btn.addEventListener('click', () => {
        this.activeCategory = btn.getAttribute('data-cat-id');
        container.querySelectorAll('.chip').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.renderProducts();
      });
    });
  },

  renderProducts() {
    const grid = document.getElementById('pos-product-grid');
    if (!grid) return;

    let filtered = this.products;

    // Filter category
    if (this.activeCategory !== 'all') {
      filtered = filtered.filter(p => p.category_id == this.activeCategory);
    }

    // Filter search
    if (this.searchQuery) {
      filtered = filtered.filter(p => 
        p.name.toLowerCase().includes(this.searchQuery) ||
        p.code.toLowerCase().includes(this.searchQuery) ||
        (p.barcode && p.barcode.toLowerCase().includes(this.searchQuery))
      );
    }

    if (filtered.length === 0) {
      grid.innerHTML = `
        <div style="grid-column: 1 / -1; text-align: center; padding: 40px 10px; color: var(--text-muted);">
          <div style="font-size: 2.5rem; margin-bottom: 8px;">🔍</div>
          <p>Không tìm thấy sản phẩm phù hợp</p>
        </div>
      `;
      return;
    }

    grid.innerHTML = filtered.map(p => {
      const isOut = p.stock_quantity <= 0;
      const isLow = p.stock_quantity > 0 && p.stock_quantity <= p.min_stock_alert;

      let stockClass = '';
      let stockText = `Tồn: ${p.stock_quantity} ${p.unit}`;
      if (isOut) {
        stockClass = 'out-of-stock';
        stockText = 'HẾT HÀNG';
      } else if (isLow) {
        stockClass = 'low-stock';
        stockText = `Sắp hết: ${p.stock_quantity} ${p.unit}`;
      }

      return `
        <div class="pos-card ${isOut ? 'disabled' : ''}" onclick="posModule.addToCart(${p.id})">
          <div class="pos-card-icon">${p.image_icon || '📦'}</div>
          <div class="pos-card-name" title="${p.name}">${p.name}</div>
          <div class="pos-card-price">${app.formatCurrency(p.selling_price)}</div>
          <div class="pos-card-stock ${stockClass}">${stockText}</div>
        </div>
      `;
    }).join('');
  },

  addToCart(productId) {
    const prod = this.products.find(p => p.id === productId);
    if (!prod) return;

    if (prod.stock_quantity <= 0) {
      app.showToast(`Sản phẩm "${prod.name}" đã hết hàng trong kho!`, 'warning');
      return;
    }

    const exist = this.cart.find(item => item.product_id === productId);
    if (exist) {
      if (exist.quantity + 1 > prod.stock_quantity) {
        app.showToast(`Chỉ còn ${prod.stock_quantity} ${prod.unit} trong kho!`, 'warning');
        return;
      }
      exist.quantity += 1;
    } else {
      this.cart.push({
        product_id: prod.id,
        code: prod.code,
        name: prod.name,
        unit: prod.unit,
        selling_price: prod.selling_price,
        cost_price: prod.cost_price,
        quantity: 1,
        max_stock: prod.stock_quantity
      });
    }

    this.renderCart();
  },

  updateQuantity(productId, delta) {
    const item = this.cart.find(i => i.product_id === productId);
    if (!item) return;

    const newQty = item.quantity + delta;
    if (newQty <= 0) {
      this.removeFromCart(productId);
      return;
    }

    if (newQty > item.max_stock) {
      app.showToast(`Kho chỉ còn ${item.max_stock} ${item.unit}!`, 'warning');
      return;
    }

    item.quantity = newQty;
    this.renderCart();
  },

  setQuantityDirect(productId, val) {
    const item = this.cart.find(i => i.product_id === productId);
    if (!item) return;

    let qty = parseInt(val) || 1;
    if (qty <= 0) qty = 1;
    if (qty > item.max_stock) {
      app.showToast(`Kho chỉ còn ${item.max_stock} ${item.unit}!`, 'warning');
      qty = item.max_stock;
    }

    item.quantity = qty;
    this.renderCart();
  },

  removeFromCart(productId) {
    this.cart = this.cart.filter(i => i.product_id !== productId);
    this.renderCart();
  },

  renderCart() {
    const container = document.getElementById('cart-items-list');
    const badgeCount = document.getElementById('cart-item-count');

    const totalUnits = this.cart.reduce((sum, i) => sum + i.quantity, 0);
    if (badgeCount) badgeCount.textContent = totalUnits;

    if (!container) return;

    if (this.cart.length === 0) {
      container.innerHTML = `
        <div class="empty-cart-message">
          <div class="empty-cart-icon">🛒</div>
          <p>Giỏ hàng đang trống</p>
          <small class="text-muted">Nhấp vào sản phẩm bên trái hoặc quét mã vạch để thêm vào giỏ.</small>
        </div>
      `;
      this.updateCalculations();
      return;
    }

    container.innerHTML = this.cart.map(item => `
      <div class="cart-item-row">
        <div class="cart-item-info">
          <span class="cart-item-title">${item.name}</span>
          <span class="cart-item-unit-price">${app.formatCurrency(item.selling_price)} / ${item.unit}</span>
        </div>
        <div class="cart-qty-ctrl">
          <button type="button" onclick="posModule.updateQuantity(${item.product_id}, -1)">-</button>
          <input type="number" min="1" max="${item.max_stock}" value="${item.quantity}"
                 onchange="posModule.setQuantityDirect(${item.product_id}, this.value)">
          <button type="button" onclick="posModule.updateQuantity(${item.product_id}, 1)">+</button>
        </div>
        <div class="cart-item-total">
          ${app.formatCurrency(item.quantity * item.selling_price)}
        </div>
        <button type="button" class="btn-item-remove" onclick="posModule.removeFromCart(${item.product_id})" title="Xóa món">✕</button>
      </div>
    `).join('');

    this.updateCalculations();
  },

  calculateSubtotal() {
    return this.cart.reduce((sum, item) => sum + item.quantity * item.selling_price, 0);
  },

  calculateTotal() {
    const subtotal = this.calculateSubtotal();
    const discountInput = document.getElementById('cart-discount-input');
    const discount = Number(discountInput?.value) || 0;
    return Math.max(0, subtotal - discount);
  },

  updateCalculations() {
    const subtotal = this.calculateSubtotal();
    const total = this.calculateTotal();

    const subtotalEl = document.getElementById('cart-subtotal');
    const totalEl = document.getElementById('cart-total-amount');
    const changeEl = document.getElementById('cart-change-amount');
    const payInput = document.getElementById('cart-customer-payment');

    if (subtotalEl) subtotalEl.textContent = app.formatCurrency(subtotal);
    if (totalEl) totalEl.textContent = app.formatCurrency(total);

    const customerPay = Number(payInput?.value) || 0;
    const change = Math.max(0, customerPay - total);

    if (changeEl) {
      changeEl.textContent = app.formatCurrency(change);
      changeEl.style.color = (customerPay > 0 && customerPay < total) ? 'var(--danger)' : '#2563eb';
    }
  },

  async processCheckout() {
    if (this.cart.length === 0) {
      app.showToast('Giỏ hàng đang trống!', 'warning');
      return;
    }

    const subtotal = this.calculateSubtotal();
    const total = this.calculateTotal();
    const payInput = document.getElementById('cart-customer-payment');
    const customerPayment = Number(payInput?.value) || total;

    const custSelect = document.getElementById('pos-customer-select');
    const customerId = custSelect?.value ? parseInt(custSelect.value) : null;

    const empSelect = document.getElementById('pos-employee-select');
    const employeeId = empSelect?.value ? parseInt(empSelect.value) : null;

    const discountInput = document.getElementById('cart-discount-input');
    const discount = Number(discountInput?.value) || 0;

    const methodSelect = document.getElementById('cart-payment-method');
    const paymentMethod = methodSelect?.value || 'Tiền mặt';

    const payload = {
      customer_id: customerId,
      employee_id: employeeId,
      items: this.cart.map(i => ({
        product_id: i.product_id,
        quantity: i.quantity,
        selling_price: i.selling_price
      })),
      discount,
      customer_payment: customerPayment,
      payment_method: paymentMethod
    };

    try {
      const res = await api.post('/api/invoices', payload);
      if (res.success) {
        app.showToast('✅ Bán hàng thành công! Đang mở hóa đơn...', 'success');

        // Show Invoice Print Modal
        this.showInvoiceModal(res.data);

        // Reset cart
        this.cart = [];
        if (discountInput) discountInput.value = 0;
        if (payInput) payInput.value = '';
        this.renderCart();

        // Refresh product stock
        await this.fetchProducts();
        this.renderProducts();

        // Refresh customer list if points updated
        await this.fetchCustomers();

        // Refresh dashboard in background
        dashboardModule.loadDashboard();
      }
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi thanh toán!', 'error');
    }
  },

  showInvoiceModal(invoice) {
    const printable = document.getElementById('invoice-printable-area');
    if (!printable) return;

    printable.innerHTML = `
      <div class="thermal-receipt">
        <div class="receipt-header">
          <h2>TẠP HÓA VIỆT</h2>
          <p>Đ/c: 123 Đường Số 1, Tân Bình, TP.HCM</p>
          <p>Hotline: 0909.123.456</p>
          <div class="receipt-divider"></div>
          <h3 style="font-size: 1rem; margin: 4px 0;">HÓA ĐƠN BÁN LẺ</h3>
        </div>

        <div class="receipt-meta">
          <div><b>Mã HĐ:</b> ${invoice.code}</div>
          <div><b>Ngày:</b> ${app.formatDateTime(invoice.invoice_date)}</div>
          <div><b>Thu ngân:</b> ${invoice.employee_name || 'Thu ngân'}</div>
          <div><b>Khách hàng:</b> ${invoice.customer_name || 'Khách lẻ'}</div>
          ${invoice.customer_phone ? `<div><b>SĐT:</b> ${invoice.customer_phone}</div>` : ''}
          <div><b>Phương thức:</b> ${invoice.payment_method}</div>
        </div>

        <div class="receipt-divider"></div>

        <table class="receipt-table">
          <thead>
            <tr>
              <th style="width: 48%;">Tên hàng</th>
              <th style="width: 14%; text-align: center;">SL</th>
              <th style="width: 18%; text-align: right;">Đơn giá</th>
              <th style="width: 20%; text-align: right;">T.Tiền</th>
            </tr>
          </thead>
          <tbody>
            ${(invoice.items || []).map(item => `
              <tr>
                <td>${item.product_name}</td>
                <td style="text-align: center;">${item.quantity}</td>
                <td style="text-align: right;">${Number(item.selling_price).toLocaleString('vi-VN')}</td>
                <td style="text-align: right;">${Number(item.total_price).toLocaleString('vi-VN')}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>

        <div class="receipt-divider"></div>

        <div class="receipt-totals">
          <div class="receipt-totals-row">
            <span>Tiền hàng:</span>
            <span>${app.formatCurrency(invoice.subtotal)}</span>
          </div>
          ${invoice.discount > 0 ? `
            <div class="receipt-totals-row">
              <span>Giảm giá:</span>
              <span>-${app.formatCurrency(invoice.discount)}</span>
            </div>
          ` : ''}
          <div class="receipt-totals-row grand-total">
            <span>TỔNG CỘNG:</span>
            <span>${app.formatCurrency(invoice.total_amount)}</span>
          </div>
          <div class="receipt-totals-row">
            <span>Tiền khách đưa:</span>
            <span>${app.formatCurrency(invoice.customer_payment)}</span>
          </div>
          <div class="receipt-totals-row">
            <span>Tiền thối lại:</span>
            <span>${app.formatCurrency(invoice.change_amount)}</span>
          </div>
        </div>

        <div class="receipt-divider"></div>

        <div class="receipt-footer">
          <p>Xin cảm ơn Quý khách & Hẹn gặp lại!</p>
          <small>Hệ thống Quản lý Tạp hóa - Powered by Antigravity</small>
        </div>
      </div>
    `;

    app.openModal('modal-invoice-detail');
  }
};
