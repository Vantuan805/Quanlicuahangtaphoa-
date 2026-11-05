// Customers Management Module
const customersModule = {
  customers: [],

  async loadCustomers() {
    try {
      const q = document.getElementById('filter-customer-search')?.value.trim() || '';
      const endpoint = q ? `/api/customers?q=${encodeURIComponent(q)}` : '/api/customers';
      const res = await api.get(endpoint);
      if (res.success) {
        this.customers = res.data;
        this.renderTable();
      }
    } catch (err) {
      console.error('Failed to load customers:', err);
      app.showToast('Lỗi khi tải khách hàng', 'error');
    }
  },

  renderTable() {
    const tbody = document.getElementById('customers-table-body');
    if (!tbody) return;

    if (this.customers.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted py-4">Không tìm thấy khách hàng nào</td></tr>';
      return;
    }

    tbody.innerHTML = this.customers.map(c => `
      <tr>
        <td><code>${c.code}</code></td>
        <td><strong>${c.name}</strong></td>
        <td>${c.phone || '<em class="text-muted">--</em>'}</td>
        <td><small class="text-muted">${c.address || '--'}</small></td>
        <td class="text-center"><span class="badge badge-success">${c.points || 0} điểm</span></td>
        <td class="text-right bold text-primary">${app.formatCurrency(c.total_spent || 0)}</td>
        <td>
          <button class="btn-action" onclick="customersModule.openEditModal(${c.id})" title="Chỉnh sửa">✏️</button>
          <button class="btn-action text-danger" onclick="customersModule.deleteCustomer(${c.id}, '${c.name.replace(/'/g, "\\'")}')" title="Xóa">🗑️</button>
        </td>
      </tr>
    `).join('');
  },

  openAddModal() {
    document.getElementById('form-customer')?.reset();
    document.getElementById('cust-id').value = '';
    document.getElementById('cust-points').value = 0;
    document.getElementById('modal-customer-title').textContent = 'Thêm khách hàng mới';
    app.openModal('modal-customer');
  },

  openEditModal(id) {
    const c = this.customers.find(item => item.id === id);
    if (!c) return;

    document.getElementById('cust-id').value = c.id;
    document.getElementById('cust-name').value = c.name;
    document.getElementById('cust-phone').value = c.phone || '';
    document.getElementById('cust-address').value = c.address || '';
    document.getElementById('cust-points').value = c.points || 0;

    document.getElementById('modal-customer-title').textContent = 'Chỉnh sửa khách hàng';
    app.openModal('modal-customer');
  },

  async handleFormSubmit(e) {
    e.preventDefault();
    const id = document.getElementById('cust-id').value;
    const payload = {
      name: document.getElementById('cust-name').value.trim(),
      phone: document.getElementById('cust-phone').value.trim(),
      address: document.getElementById('cust-address').value.trim(),
      points: Number(document.getElementById('cust-points').value) || 0
    };

    try {
      if (id) {
        await api.put(`/api/customers/${id}`, payload);
        app.showToast('Cập nhật khách hàng thành công!');
      } else {
        await api.post('/api/customers', payload);
        app.showToast('Thêm khách hàng mới thành công!');
      }
      app.closeModal('modal-customer');
      this.loadCustomers();
      // If POS is loaded, reload its customer dropdown
      if (typeof posModule !== 'undefined') posModule.fetchCustomers();
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi lưu khách hàng', 'error');
    }
  },

  async deleteCustomer(id, name) {
    if (!confirm(`Bạn có chắc chắn muốn xóa khách hàng "${name}"?`)) return;

    try {
      await api.delete(`/api/customers/${id}`);
      app.showToast('Đã xóa khách hàng!');
      this.loadCustomers();
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi xóa khách hàng', 'error');
    }
  }
};

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-add-customer')?.addEventListener('click', () => {
    customersModule.openAddModal();
  });

  document.getElementById('form-customer')?.addEventListener('submit', (e) => {
    customersModule.handleFormSubmit(e);
  });

  document.getElementById('filter-customer-search')?.addEventListener('input', () => {
    customersModule.loadCustomers();
  });
});
