// Inventory & Stock Tracking Module
const inventoryModule = {
  inventoryList: [],
  summary: {},

  async loadInventory() {
    try {
      const q = document.getElementById('filter-inventory-search')?.value.trim() || '';
      const status = document.getElementById('filter-inventory-status')?.value || 'all';

      const params = new URLSearchParams();
      if (q) params.append('q', q);
      if (status !== 'all') params.append('status', status);

      const res = await api.get(`/api/inventory?${params.toString()}`);
      if (res.success) {
        this.inventoryList = res.data.rows;
        this.summary = res.data.summary;
        this.renderSummary();
        this.renderTable();
      }
    } catch (err) {
      console.error('Failed to load inventory:', err);
      app.showToast('Lỗi khi tải thông tin kho hàng', 'error');
    }
  },

  renderSummary() {
    const s = this.summary || {};
    document.getElementById('inv-stat-prods').textContent = s.total_products || 0;
    document.getElementById('inv-stat-units').textContent = Number(s.total_units || 0).toLocaleString('vi-VN');
    document.getElementById('inv-stat-value').textContent = app.formatCurrency(s.total_value || 0);
    document.getElementById('inv-stat-low').textContent = s.low_count || 0;
    document.getElementById('inv-stat-out').textContent = s.out_count || 0;
  },

  renderTable() {
    const tbody = document.getElementById('inventory-table-body');
    if (!tbody) return;

    if (this.inventoryList.length === 0) {
      tbody.innerHTML = '<tr><td colspan="10" class="text-center text-muted py-4">Không tìm thấy sản phẩm trong kho</td></tr>';
      return;
    }

    tbody.innerHTML = this.inventoryList.map(p => {
      let statusBadge = '<span class="badge badge-success">Còn hàng</span>';
      if (p.stock_status === 'Hết hàng') {
        statusBadge = '<span class="badge badge-danger">Hết hàng</span>';
      } else if (p.stock_status === 'Sắp hết') {
        statusBadge = '<span class="badge badge-warning">Sắp hết hàng</span>';
      }

      return `
        <tr>
          <td><code>${p.code}</code></td>
          <td><strong>${p.name}</strong></td>
          <td>${p.category_name || '--'}</td>
          <td><span class="badge badge-info">${p.unit}</span></td>
          <td class="text-right text-muted">${app.formatCurrency(p.cost_price)}</td>
          <td class="text-center bold ${p.stock_quantity <= p.min_stock_alert ? 'text-danger' : ''}">${p.stock_quantity}</td>
          <td class="text-center text-muted">${p.min_stock_alert}</td>
          <td class="text-right bold text-primary">${app.formatCurrency(p.inventory_value)}</td>
          <td>${statusBadge}</td>
          <td>
            <button class="btn btn-sm btn-outline-secondary" onclick="inventoryModule.openAdjustModal(${p.id})">⚖️ Kiểm kê</button>
          </td>
        </tr>
      `;
    }).join('');
  },

  openAdjustModal(productId) {
    const p = this.inventoryList.find(item => item.id === productId);
    if (!p) return;

    document.getElementById('adj-product-id').value = p.id;
    document.getElementById('adj-product-name').textContent = `${p.name} (${p.unit})`;
    document.getElementById('adj-old-qty').value = `${p.stock_quantity} ${p.unit}`;
    document.getElementById('adj-new-qty').value = p.stock_quantity;
    document.getElementById('adj-reason').value = 'Kiểm kê định kỳ';

    app.openModal('modal-adjust-stock');
  },

  async handleAdjustSubmit(e) {
    e.preventDefault();
    const productId = parseInt(document.getElementById('adj-product-id').value);
    const newQuantity = parseInt(document.getElementById('adj-new-qty').value);
    const reason = document.getElementById('adj-reason').value;

    try {
      const res = await api.post('/api/inventory/adjust', {
        product_id: productId,
        new_quantity: newQuantity,
        reason
      });

      if (res.success) {
        app.showToast('✅ Đã điều chỉnh và lưu lịch sử kiểm kê!', 'success');
        app.closeModal('modal-adjust-stock');
        this.loadInventory();
        dashboardModule.loadDashboard();
      }
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi kiểm kê kho', 'error');
    }
  },

  async viewAdjustmentsHistory() {
    try {
      const res = await api.get('/api/inventory/adjustments');
      if (!res.success) return;
      const list = res.data;

      const tbody = document.getElementById('adjustments-table-body');
      if (!tbody) return;

      if (list.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted py-3">Chưa có lịch sử kiểm kê nào</td></tr>';
      } else {
        tbody.innerHTML = list.map(item => {
          const diff = item.change_quantity;
          const diffText = diff > 0 ? `+${diff}` : `${diff}`;
          const diffClass = diff > 0 ? 'text-primary' : (diff < 0 ? 'text-danger' : 'text-muted');

          return `
            <tr>
              <td><code>${item.code}</code></td>
              <td><small class="text-muted">${app.formatDateTime(item.adjusted_at)}</small></td>
              <td><strong>${item.product_name}</strong> (${item.unit})</td>
              <td class="text-center text-muted">${item.old_quantity}</td>
              <td class="text-center bold">${item.new_quantity}</td>
              <td class="text-center bold ${diffClass}">${diffText}</td>
              <td><small>${item.reason || '--'}</small></td>
            </tr>
          `;
        }).join('');
      }

      app.openModal('modal-adjustments-history');
    } catch (err) {
      app.showToast('Không thể tải lịch sử kiểm kê', 'error');
    }
  }
};

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('form-adjust-stock')?.addEventListener('submit', (e) => {
    inventoryModule.handleAdjustSubmit(e);
  });

  document.getElementById('btn-view-adjustments')?.addEventListener('click', () => {
    inventoryModule.viewAdjustmentsHistory();
  });

  document.getElementById('filter-inventory-search')?.addEventListener('input', () => {
    inventoryModule.loadInventory();
  });

  document.getElementById('filter-inventory-status')?.addEventListener('change', () => {
    inventoryModule.loadInventory();
  });
});
