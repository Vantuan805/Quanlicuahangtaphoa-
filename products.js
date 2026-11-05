// Product Management Module
const productsModule = {
  products: [],
  categories: [],
  suppliers: [],

  async loadProducts() {
    try {
      const search = document.getElementById('filter-product-search')?.value || '';
      const categoryId = document.getElementById('filter-product-category')?.value || '';
      const lowStock = document.getElementById('filter-product-lowstock')?.checked || false;

      let queryParams = new URLSearchParams();
      if (search) queryParams.append('q', search);
      if (categoryId) queryParams.append('category_id', categoryId);
      if (lowStock) queryParams.append('low_stock', 'true');

      const res = await api.get(`/api/products?${queryParams.toString()}`);
      if (res.success) {
        this.products = res.data;
        this.renderTable();
      }
    } catch (err) {
      console.error('Failed to load products:', err);
      app.showToast('Lỗi khi tải danh sách sản phẩm', 'error');
    }
  },

  async loadFilterCategories() {
    try {
      const [resCat, resSup] = await Promise.all([
        api.get('/api/categories'),
        api.get('/api/suppliers')
      ]);

      if (resCat.success) {
        this.categories = resCat.data;
        const filterSelect = document.getElementById('filter-product-category');
        if (filterSelect) {
          const currentVal = filterSelect.value;
          filterSelect.innerHTML = '<option value="">-- Tất cả loại sản phẩm --</option>' +
            this.categories.map(c => `<option value="${c.id}">${c.name}</option>`).join('');
          filterSelect.value = currentVal;
        }

        const modalCatSelect = document.getElementById('prod-category');
        if (modalCatSelect) {
          modalCatSelect.innerHTML = '<option value="">-- Chọn loại sản phẩm --</option>' +
            this.categories.map(c => `<option value="${c.id}">${c.name}</option>`).join('');
        }
      }

      if (resSup.success) {
        this.suppliers = resSup.data;
        const modalSupSelect = document.getElementById('prod-supplier');
        if (modalSupSelect) {
          modalSupSelect.innerHTML = '<option value="">-- Chọn nhà cung cấp --</option>' +
            this.suppliers.map(s => `<option value="${s.id}">${s.name}</option>`).join('');
        }
      }
    } catch (err) {
      console.error('Failed to load product filters:', err);
    }
  },

  renderTable() {
    const tbody = document.getElementById('products-table-body');
    if (!tbody) return;

    if (this.products.length === 0) {
      tbody.innerHTML = '<tr><td colspan="11" class="text-center text-muted py-4">Không tìm thấy sản phẩm nào</td></tr>';
      return;
    }

    tbody.innerHTML = this.products.map(p => {
      const isOut = p.stock_quantity <= 0;
      const isLow = p.stock_quantity > 0 && p.stock_quantity <= p.min_stock_alert;

      let stockBadge = `<span class="badge badge-success">${p.stock_quantity}</span>`;
      if (isOut) stockBadge = `<span class="badge badge-danger">0 (Hết hàng)</span>`;
      else if (isLow) stockBadge = `<span class="badge badge-warning">${p.stock_quantity} (Sắp hết)</span>`;

      return `
        <tr>
          <td style="font-size: 1.4rem;">${p.image_icon || '📦'}</td>
          <td><code>${p.code}</code></td>
          <td class="text-muted"><small>${p.barcode || '--'}</small></td>
          <td><strong>${p.name}</strong></td>
          <td>${p.category_name || '<em class="text-muted">Chưa phân loại</em>'}</td>
          <td><span class="badge badge-info">${p.unit}</span></td>
          <td class="text-right text-muted">${app.formatCurrency(p.cost_price)}</td>
          <td class="text-right bold text-primary">${app.formatCurrency(p.selling_price)}</td>
          <td class="text-center">${stockBadge}</td>
          <td class="text-center text-muted">${p.min_stock_alert}</td>
          <td>
            <button class="btn-action" onclick="productsModule.openEditModal(${p.id})" title="Chỉnh sửa">✏️</button>
            <button class="btn-action text-danger" onclick="productsModule.deleteProduct(${p.id}, '${p.name.replace(/'/g, "\\'")}')" title="Xóa">🗑️</button>
          </td>
        </tr>
      `;
    }).join('');
  },

  openAddModal() {
    document.getElementById('form-product')?.reset();
    document.getElementById('prod-id').value = '';
    document.getElementById('prod-icon').value = '📦';
    document.getElementById('prod-stock').value = 0;
    document.getElementById('prod-min-alert').value = 10;
    document.getElementById('modal-product-title').textContent = 'Thêm sản phẩm mới';
    this.loadFilterCategories();
    app.openModal('modal-product');
  },

  openEditModal(id) {
    const prod = this.products.find(p => p.id === id);
    if (!prod) return;

    this.loadFilterCategories();
    document.getElementById('prod-id').value = prod.id;
    document.getElementById('prod-code').value = prod.code;
    document.getElementById('prod-barcode').value = prod.barcode || '';
    document.getElementById('prod-name').value = prod.name;
    document.getElementById('prod-category').value = prod.category_id || '';
    document.getElementById('prod-supplier').value = prod.supplier_id || '';
    document.getElementById('prod-unit').value = prod.unit;
    document.getElementById('prod-cost').value = prod.cost_price;
    document.getElementById('prod-price').value = prod.selling_price;
    document.getElementById('prod-stock').value = prod.stock_quantity;
    document.getElementById('prod-min-alert').value = prod.min_stock_alert;
    document.getElementById('prod-icon').value = prod.image_icon || '📦';

    document.getElementById('modal-product-title').textContent = 'Chỉnh sửa sản phẩm';
    app.openModal('modal-product');
  },

  async handleFormSubmit(e) {
    e.preventDefault();
    const id = document.getElementById('prod-id').value;

    const payload = {
      code: document.getElementById('prod-code').value.trim(),
      barcode: document.getElementById('prod-barcode').value.trim(),
      name: document.getElementById('prod-name').value.trim(),
      category_id: document.getElementById('prod-category').value || null,
      supplier_id: document.getElementById('prod-supplier').value || null,
      unit: document.getElementById('prod-unit').value.trim() || 'Cái',
      cost_price: Number(document.getElementById('prod-cost').value) || 0,
      selling_price: Number(document.getElementById('prod-price').value) || 0,
      stock_quantity: Number(document.getElementById('prod-stock').value) || 0,
      min_stock_alert: Number(document.getElementById('prod-min-alert').value) || 10,
      image_icon: document.getElementById('prod-icon').value.trim() || '📦'
    };

    try {
      if (id) {
        await api.put(`/api/products/${id}`, payload);
        app.showToast('Cập nhật sản phẩm thành công!');
      } else {
        await api.post('/api/products', payload);
        app.showToast('Thêm sản phẩm mới thành công!');
      }
      app.closeModal('modal-product');
      this.loadProducts();
      dashboardModule.loadDashboard();
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi lưu sản phẩm', 'error');
    }
  },

  async deleteProduct(id, name) {
    if (!confirm(`Bạn có chắc chắn muốn xóa sản phẩm "${name}"?`)) return;

    try {
      await api.delete(`/api/products/${id}`);
      app.showToast('Đã xóa sản phẩm thành công!');
      this.loadProducts();
      dashboardModule.loadDashboard();
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi xóa sản phẩm', 'error');
    }
  }
};

// Event Listeners for Products
window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-add-product')?.addEventListener('click', () => {
    productsModule.openAddModal();
  });

  document.getElementById('form-product')?.addEventListener('submit', (e) => {
    productsModule.handleFormSubmit(e);
  });

  document.getElementById('filter-product-search')?.addEventListener('input', () => {
    productsModule.loadProducts();
  });

  document.getElementById('filter-product-category')?.addEventListener('change', () => {
    productsModule.loadProducts();
  });

  document.getElementById('filter-product-lowstock')?.addEventListener('change', () => {
    productsModule.loadProducts();
  });
});
