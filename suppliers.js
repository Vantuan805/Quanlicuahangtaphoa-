// Suppliers Management Module
const suppliersModule = {
  suppliers: [],

  async loadSuppliers() {
    try {
      const res = await api.get('/api/suppliers');
      if (res.success) {
        this.suppliers = res.data;
        this.renderTable();
      }
    } catch (err) {
      console.error('Failed to load suppliers:', err);
      app.showToast('Lỗi khi tải nhà cung cấp', 'error');
    }
  },

  renderTable() {
    const tbody = document.getElementById('suppliers-table-body');
    if (!tbody) return;

    if (this.suppliers.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted py-4">Chưa có nhà cung cấp nào</td></tr>';
      return;
    }

    tbody.innerHTML = this.suppliers.map(s => `
      <tr>
        <td><code>${s.code}</code></td>
        <td><strong>${s.name}</strong></td>
        <td>${s.phone || '<em class="text-muted">--</em>'}</td>
        <td>${s.email || '<em class="text-muted">--</em>'}</td>
        <td><small class="text-muted">${s.address || '--'}</small></td>
        <td><small>${s.notes || '--'}</small></td>
        <td>
          <button class="btn-action" onclick="suppliersModule.openEditModal(${s.id})" title="Chỉnh sửa">✏️</button>
          <button class="btn-action text-danger" onclick="suppliersModule.deleteSupplier(${s.id}, '${s.name.replace(/'/g, "\\'")}')" title="Xóa">🗑️</button>
        </td>
      </tr>
    `).join('');
  },

  openAddModal() {
    document.getElementById('form-supplier')?.reset();
    document.getElementById('sup-id').value = '';
    document.getElementById('modal-supplier-title').textContent = 'Thêm nhà cung cấp mới';
    app.openModal('modal-supplier');
  },

  openEditModal(id) {
    const s = this.suppliers.find(item => item.id === id);
    if (!s) return;

    document.getElementById('sup-id').value = s.id;
    document.getElementById('sup-name').value = s.name;
    document.getElementById('sup-phone').value = s.phone || '';
    document.getElementById('sup-email').value = s.email || '';
    document.getElementById('sup-address').value = s.address || '';
    document.getElementById('sup-notes').value = s.notes || '';

    document.getElementById('modal-supplier-title').textContent = 'Chỉnh sửa nhà cung cấp';
    app.openModal('modal-supplier');
  },

  async handleFormSubmit(e) {
    e.preventDefault();
    const id = document.getElementById('sup-id').value;
    const payload = {
      name: document.getElementById('sup-name').value.trim(),
      phone: document.getElementById('sup-phone').value.trim(),
      email: document.getElementById('sup-email').value.trim(),
      address: document.getElementById('sup-address').value.trim(),
      notes: document.getElementById('sup-notes').value.trim()
    };

    try {
      if (id) {
        await api.put(`/api/suppliers/${id}`, payload);
        app.showToast('Cập nhật nhà cung cấp thành công!');
      } else {
        await api.post('/api/suppliers', payload);
        app.showToast('Thêm nhà cung cấp mới thành công!');
      }
      app.closeModal('modal-supplier');
      this.loadSuppliers();
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi lưu nhà cung cấp', 'error');
    }
  },

  async deleteSupplier(id, name) {
    if (!confirm(`Bạn có chắc muốn xóa nhà cung cấp "${name}"?`)) return;

    try {
      await api.delete(`/api/suppliers/${id}`);
      app.showToast('Đã xóa nhà cung cấp!');
      this.loadSuppliers();
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi xóa nhà cung cấp', 'error');
    }
  }
};

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-add-supplier')?.addEventListener('click', () => {
    suppliersModule.openAddModal();
  });

  document.getElementById('form-supplier')?.addEventListener('submit', (e) => {
    suppliersModule.handleFormSubmit(e);
  });
});
