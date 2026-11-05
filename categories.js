// Categories Management Module
const categoriesModule = {
  categories: [],

  async loadCategories() {
    try {
      const res = await api.get('/api/categories');
      if (res.success) {
        this.categories = res.data;
        this.renderTable();
      }
    } catch (err) {
      console.error('Failed to load categories:', err);
      app.showToast('Lỗi khi tải loại sản phẩm', 'error');
    }
  },

  renderTable() {
    const tbody = document.getElementById('categories-table-body');
    if (!tbody) return;

    if (this.categories.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Chưa có loại sản phẩm nào</td></tr>';
      return;
    }

    tbody.innerHTML = this.categories.map(c => `
      <tr>
        <td>${c.id}</td>
        <td><code>${c.code}</code></td>
        <td><strong>${c.name}</strong></td>
        <td><small class="text-muted">${c.description || '--'}</small></td>
        <td class="text-center"><span class="badge badge-info">${c.product_count || 0} sản phẩm</span></td>
        <td>
          <button class="btn-action" onclick="categoriesModule.openEditModal(${c.id})" title="Chỉnh sửa">✏️</button>
          <button class="btn-action text-danger" onclick="categoriesModule.deleteCategory(${c.id}, '${c.name.replace(/'/g, "\\'")}')" title="Xóa">🗑️</button>
        </td>
      </tr>
    `).join('');
  },

  openAddModal() {
    document.getElementById('form-category')?.reset();
    document.getElementById('cat-id').value = '';
    document.getElementById('modal-category-title').textContent = 'Thêm loại sản phẩm';
    app.openModal('modal-category');
  },

  openEditModal(id) {
    const cat = this.categories.find(c => c.id === id);
    if (!cat) return;

    document.getElementById('cat-id').value = cat.id;
    document.getElementById('cat-name').value = cat.name;
    document.getElementById('cat-desc').value = cat.description || '';
    document.getElementById('modal-category-title').textContent = 'Chỉnh sửa loại sản phẩm';
    app.openModal('modal-category');
  },

  async handleFormSubmit(e) {
    e.preventDefault();
    const id = document.getElementById('cat-id').value;
    const payload = {
      name: document.getElementById('cat-name').value.trim(),
      description: document.getElementById('cat-desc').value.trim()
    };

    try {
      if (id) {
        await api.put(`/api/categories/${id}`, payload);
        app.showToast('Cập nhật loại sản phẩm thành công!');
      } else {
        await api.post('/api/categories', payload);
        app.showToast('Thêm loại sản phẩm mới thành công!');
      }
      app.closeModal('modal-category');
      this.loadCategories();
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi lưu loại sản phẩm', 'error');
    }
  },

  async deleteCategory(id, name) {
    if (!confirm(`Bạn có chắc chắn muốn xóa loại sản phẩm "${name}"?`)) return;

    try {
      await api.delete(`/api/categories/${id}`);
      app.showToast('Đã xóa loại sản phẩm!');
      this.loadCategories();
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi xóa loại sản phẩm', 'error');
    }
  }
};

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-add-category')?.addEventListener('click', () => {
    categoriesModule.openAddModal();
  });

  document.getElementById('form-category')?.addEventListener('submit', (e) => {
    categoriesModule.handleFormSubmit(e);
  });
});
