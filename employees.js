// Employees Management Module
const employeesModule = {
  employees: [],

  async loadEmployees() {
    try {
      const res = await api.get('/api/employees');
      if (res.success) {
        this.employees = res.data;
        this.renderTable();
      }
    } catch (err) {
      console.error('Failed to load employees:', err);
      app.showToast('Lỗi khi tải danh sách nhân viên', 'error');
    }
  },

  renderTable() {
    const tbody = document.getElementById('employees-table-body');
    if (!tbody) return;

    if (this.employees.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Chưa có nhân viên nào</td></tr>';
      return;
    }

    tbody.innerHTML = this.employees.map(e => `
      <tr>
        <td><code>${e.code}</code></td>
        <td><strong>${e.name}</strong></td>
        <td>${e.phone || '<em class="text-muted">--</em>'}</td>
        <td><span class="badge badge-info">${e.role}</span></td>
        <td>
          ${e.status === 'active' 
            ? '<span class="badge badge-success">Đang làm việc</span>' 
            : '<span class="badge badge-danger">Đã nghỉ</span>'}
        </td>
        <td>
          <button class="btn-action" onclick="employeesModule.openEditModal(${e.id})" title="Chỉnh sửa">✏️</button>
          <button class="btn-action text-danger" onclick="employeesModule.deleteEmployee(${e.id}, '${e.name.replace(/'/g, "\\'")}')" title="Xóa">🗑️</button>
        </td>
      </tr>
    `).join('');
  },

  openAddModal() {
    document.getElementById('form-employee')?.reset();
    document.getElementById('emp-id').value = '';
    
    // Tự động gợi ý mã nhân viên kế tiếp (ví dụ: NV04)
    let nextNum = 1;
    if (this.employees && this.employees.length > 0) {
      const nums = this.employees
        .map(e => parseInt((e.code || '').replace(/\D/g, '')))
        .filter(n => !isNaN(n));
      if (nums.length > 0) {
        nextNum = Math.max(...nums) + 1;
      }
    }
    const suggestedCode = 'NV' + String(nextNum).padStart(2, '0');
    const codeInput = document.getElementById('emp-code');
    if (codeInput) {
      codeInput.value = suggestedCode;
      codeInput.readOnly = false;
    }

    document.getElementById('emp-status').value = 'active';
    document.getElementById('modal-employee-title').textContent = 'Thêm nhân viên mới';
    app.openModal('modal-employee');
  },

  openEditModal(id) {
    const emp = this.employees.find(item => item.id === id);
    if (!emp) return;

    document.getElementById('emp-id').value = emp.id;
    const codeInput = document.getElementById('emp-code');
    if (codeInput) {
      codeInput.value = emp.code;
      codeInput.readOnly = true; // Không sửa mã khi edit
    }
    document.getElementById('emp-name').value = emp.name;
    document.getElementById('emp-phone').value = emp.phone || '';
    document.getElementById('emp-role').value = emp.role;
    document.getElementById('emp-status').value = emp.status;

    document.getElementById('modal-employee-title').textContent = 'Chỉnh sửa nhân viên';
    app.openModal('modal-employee');
  },

  async handleFormSubmit(e) {
    e.preventDefault();
    const id = document.getElementById('emp-id').value;
    const code = document.getElementById('emp-code')?.value.trim();
    const name = document.getElementById('emp-name')?.value.trim();

    if (!name) {
      app.showToast('Vui lòng nhập họ và tên nhân viên!', 'warning');
      return;
    }

    const payload = {
      code,
      name,
      phone: document.getElementById('emp-phone')?.value.trim() || '',
      role: document.getElementById('emp-role')?.value || 'Thu ngân',
      status: document.getElementById('emp-status')?.value || 'active'
    };

    try {
      if (id) {
        await api.put(`/api/employees/${id}`, payload);
        app.showToast('Cập nhật nhân viên thành công!');
      } else {
        await api.post('/api/employees', payload);
        app.showToast('Thêm nhân viên mới thành công!');
      }
      app.closeModal('modal-employee');
      this.loadEmployees();

      // Cập nhật lại dropdown nhân viên ở POS và Phiếu nhập nếu đang mở
      if (typeof posModule !== 'undefined' && posModule.fetchEmployees) {
        posModule.fetchEmployees();
      }
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi lưu nhân viên', 'error');
    }
  },

  async deleteEmployee(id, name) {
    if (!confirm(`Bạn có chắc muốn xóa nhân viên "${name}"?`)) return;

    try {
      await api.delete(`/api/employees/${id}`);
      app.showToast('Đã xóa nhân viên!');
      this.loadEmployees();
    } catch (err) {
      app.showToast(err.message || 'Lỗi khi xóa nhân viên', 'error');
    }
  }
};

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-add-employee')?.addEventListener('click', () => {
    employeesModule.openAddModal();
  });

  document.getElementById('form-employee')?.addEventListener('submit', (e) => {
    employeesModule.handleFormSubmit(e);
  });
});
