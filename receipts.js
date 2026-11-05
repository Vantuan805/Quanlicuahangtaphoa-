// Goods Receipts (Phiếu Nhập Hàng) Module
const receiptsModule = {
  receipts: [],
  productsList: [],
  suppliersList: [],
  employeesList: [],

  async loadReceipts() {
    try {
      const res = await api.get('/api/receipts');
      if (res.success) {
        this.receipts = res.data;
        this.renderTable();
      }
    } catch (err) {
      console.error('Failed to load receipts:', err);
      app.showToast('Lỗi khi tải phiếu nhập hàng', 'error');
    }
  },

  renderTable() {
    const tbody = document.getElementById('receipts-table-body');
    if (!tbody) return;

    if (this.receipts.length === 0) {
      tbody.innerHTML = '<tr><td colspan="8" class="text-center text-muted py-4">Chưa có phiếu nhập hàng nào</td></tr>';
      return;
    }

    tbody.innerHTML = this.receipts.map(r => `
      <tr>
        <td><code>${r.code}</code></td>
        <td class="text-muted"><small>${app.formatDateTime(r.receipt_date)}</small></td>
        <td><strong>${r.supplier_name || 'NCC không xác định'}</strong></td>
        <td>${r.employee_name || '--'}</td>
        <td class="text-center"><span class="badge badge-info">${r.item_count || 0} món</span></td>
        <td class="text-right bold text-primary">${app.formatCurrency(r.total_amount)}</td>
        <td><small class="text-muted">${r.notes || '--'}</small></td>
        <td>
          <button class="btn btn-sm btn-outline-primary" onclick="receiptsModule.viewDetail(${r.id})">🔍 Xem chi tiết</button>
        </td>
      </tr>
    `).join('');
  },

  async openCreateModal() {
    try {
      const [resProd, resSup, resEmp] = await Promise.all([
        api.get('/api/products'),
        api.get('/api/suppliers'),
        api.get('/api/employees')
      ]);

      if (resProd.success) this.productsList = resProd.data;
      if (resSup.success) this.suppliersList = resSup.data;
      if (resEmp.success) this.employeesList = resEmp.data;

      // Populate Supplier dropdown
      const supSelect = document.getElementById('receipt-supplier');
      if (supSelect) {
        supSelect.innerHTML = '<option value="">-- Chọn nhà cung cấp --</option>' +
          this.suppliersList.map(s => `<option value="${s.id}">${s.name}</option>`).join('');
      }

      // Populate Employee dropdown
      const empSelect = document.getElementById('receipt-employee');
      if (empSelect) {
        empSelect.innerHTML = '<option value="">-- Người lập phiếu --</option>' +
          this.employeesList.filter(e => e.status === 'active').map(e => `<option value="${e.id}">${e.name} (${e.role})</option>`).join('');
      }

      // Reset form and items table
      document.getElementById('form-receipt')?.reset();
      const tbody = document.getElementById('receipt-items-tbody');
      if (tbody) {
        tbody.innerHTML = '';
        // Add one initial row
        this.addRow();
      }
      this.updateTotalDisplay();
      app.openModal('modal-receipt-create');
    } catch (err) {
      app.showToast('Lỗi chuẩn bị dữ liệu phiếu nhập', 'error');
    }
  },

  addRow() {
    const tbody = document.getElementById('receipt-items-tbody');
    if (!tbody) return;

    const rowId = 'row-' + Date.now() + '-' + Math.floor(Math.random() * 1000);
    const tr = document.createElement('tr');
    tr.id = rowId;

    const prodOptions = this.productsList.map(p => 
      `<option value="${p.id}" data-cost="${p.cost_price}">${p.name} (${p.unit}) - Giá vốn hiện tại: ${app.formatCurrency(p.cost_price)}</option>`
    ).join('');

    tr.innerHTML = `
      <td>
        <select class="form-control receipt-prod-select" onchange="receiptsModule.onProductSelected('${rowId}')" required>
          <option value="">-- Chọn sản phẩm --</option>
          ${prodOptions}
        </select>
      </td>
      <td>
        <input type="number" class="form-control receipt-qty-input" min="1" value="10" oninput="receiptsModule.updateTotalDisplay()" required>
      </td>
      <td>
        <input type="number" class="form-control receipt-cost-input" min="0" step="100" value="0" oninput="receiptsModule.updateTotalDisplay()" required>
      </td>
      <td class="text-center">
        <button type="button" class="btn-action text-danger" onclick="receiptsModule.removeRow('${rowId}')">✕</button>
      </td>
    `;

    tbody.appendChild(tr);
  },

  onProductSelected(rowId) {
    const row = document.getElementById(rowId);
    if (!row) return;

    const select = row.querySelector('.receipt-prod-select');
    const costInput = row.querySelector('.receipt-cost-input');

    if (select && costInput) {
      const selectedOpt = select.options[select.selectedIndex];
      const defaultCost = selectedOpt.getAttribute('data-cost');
      if (defaultCost) {
        costInput.value = defaultCost;
      }
    }
    this.updateTotalDisplay();
  },

  removeRow(rowId) {
    const row = document.getElementById(rowId);
    if (row) {
      row.remove();
      this.updateTotalDisplay();
    }
  },

  updateTotalDisplay() {
    let total = 0;
    document.querySelectorAll('#receipt-items-tbody tr').forEach(row => {
      const qty = Number(row.querySelector('.receipt-qty-input')?.value) || 0;
      const cost = Number(row.querySelector('.receipt-cost-input')?.value) || 0;
      total += qty * cost;
    });

    const display = document.getElementById('receipt-total-display');
    if (display) display.textContent = app.formatCurrency(total);
  },

  async handleFormSubmit(e) {
    e.preventDefault();

    const supplier_id = parseInt(document.getElementById('receipt-supplier')?.value);
    const employee_id = parseInt(document.getElementById('receipt-employee')?.value) || null;
    const notes = document.getElementById('receipt-notes')?.value.trim() || '';

    if (!supplier_id) {
      app.showToast('Vui lòng chọn Nhà cung cấp!', 'warning');
      return;
    }

    const items = [];
    let valid = true;

    document.querySelectorAll('#receipt-items-tbody tr').forEach(row => {
      const prodId = parseInt(row.querySelector('.receipt-prod-select')?.value);
      const qty = parseInt(row.querySelector('.receipt-qty-input')?.value);
      const cost = Number(row.querySelector('.receipt-cost-input')?.value);

      if (!prodId || isNaN(prodId)) {
        valid = false;
        return;
      }

      items.push({
        product_id: prodId,
        quantity: qty > 0 ? qty : 1,
        cost_price: cost >= 0 ? cost : 0
      });
    });

    if (!valid || items.length === 0) {
      app.showToast('Vui lòng chọn đầy đủ sản phẩm cho các dòng!', 'warning');
      return;
    }

    try {
      const res = await api.post('/api/receipts', {
        supplier_id,
        employee_id,
        items,
        notes
      });

      if (res.success) {
        app.showToast(`✅ Tạo phiếu nhập ${res.data.code} thành công! Kho đã được cập nhật.`, 'success');
        app.closeModal('modal-receipt-create');
        this.loadReceipts();
        // Refresh products and dashboard
        productsModule.loadProducts();
        dashboardModule.loadDashboard();
      }
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi lập phiếu nhập', 'error');
    }
  },

  async viewDetail(id) {
    try {
      const res = await api.get(`/api/receipts/${id}`);
      if (!res.success) return;
      const r = res.data;

      const body = document.getElementById('receipt-detail-body');
      if (!body) return;

      body.innerHTML = `
        <div class="mb-3">
          <div class="d-flex justify-between">
            <h4>Mã phiếu: <code class="text-primary">${r.code}</code></h4>
            <span class="text-muted">${app.formatDateTime(r.receipt_date)}</span>
          </div>
          <div class="mt-2" style="font-size: 0.9rem;">
            <div><b>Nhà cung cấp:</b> ${r.supplier_name}</div>
            <div><b>Số điện thoại:</b> ${r.supplier_phone || '--'}</div>
            <div><b>Địa chỉ:</b> ${r.supplier_address || '--'}</div>
            <div><b>Người lập phiếu:</b> ${r.employee_name || '--'}</div>
            ${r.notes ? `<div><b>Ghi chú:</b> ${r.notes}</div>` : ''}
          </div>
        </div>

        <h4>Danh sách mặt hàng nhập:</h4>
        <div class="table-responsive mt-2">
          <table class="table table-bordered">
            <thead>
              <tr>
                <th>Mã SP</th>
                <th>Tên sản phẩm</th>
                <th>ĐVT</th>
                <th class="text-center">Số lượng</th>
                <th class="text-right">Đơn giá nhập</th>
                <th class="text-right">Thành tiền</th>
              </tr>
            </thead>
            <tbody>
              ${(r.items || []).map(i => `
                <tr>
                  <td><code>${i.product_code}</code></td>
                  <td><strong>${i.product_name}</strong></td>
                  <td>${i.unit}</td>
                  <td class="text-center bold">${i.quantity}</td>
                  <td class="text-right">${app.formatCurrency(i.cost_price)}</td>
                  <td class="text-right bold text-primary">${app.formatCurrency(i.total_price)}</td>
                </tr>
              `).join('')}
            </tbody>
            <tfoot>
              <tr>
                <td colspan="5" class="text-right bold" style="font-size: 1rem;">TỔNG TIỀN PHIẾU NHẬP:</td>
                <td class="text-right bold text-primary" style="font-size: 1.15rem;">${app.formatCurrency(r.total_amount)}</td>
              </tr>
            </tfoot>
          </table>
        </div>
      `;

      app.openModal('modal-receipt-detail');
    } catch (err) {
      app.showToast('Không thể tải chi tiết phiếu nhập', 'error');
    }
  }
};

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-create-receipt')?.addEventListener('click', () => {
    receiptsModule.openCreateModal();
  });

  document.getElementById('btn-receipt-add-row')?.addEventListener('click', () => {
    receiptsModule.addRow();
  });

  document.getElementById('form-receipt')?.addEventListener('submit', (e) => {
    receiptsModule.handleFormSubmit(e);
  });
});
