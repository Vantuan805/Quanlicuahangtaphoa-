// Invoices (Hóa Đơn Bán Hàng) Module
const invoicesModule = {
  invoices: [],

  async loadInvoices() {
    try {
      const q = document.getElementById('filter-invoice-search')?.value.trim() || '';
      const from = document.getElementById('filter-invoice-from')?.value || '';
      const to = document.getElementById('filter-invoice-to')?.value || '';

      const params = new URLSearchParams();
      if (q) params.append('q', q);
      if (from) params.append('from', from);
      if (to) params.append('to', to);

      const res = await api.get(`/api/invoices?${params.toString()}`);
      if (res.success) {
        this.invoices = res.data;
        this.renderTable();
      }
    } catch (err) {
      console.error('Failed to load invoices:', err);
      app.showToast('Lỗi khi tải danh sách hóa đơn', 'error');
    }
  },

  renderTable() {
    const tbody = document.getElementById('invoices-table-body');
    if (!tbody) return;

    if (this.invoices.length === 0) {
      tbody.innerHTML = '<tr><td colspan="10" class="text-center text-muted py-4">Không tìm thấy hóa đơn nào</td></tr>';
      return;
    }

    tbody.innerHTML = this.invoices.map(inv => `
      <tr>
        <td><code>${inv.code}</code></td>
        <td class="text-muted"><small>${app.formatDateTime(inv.invoice_date)}</small></td>
        <td><strong>${inv.customer_name || '<em class="text-muted">Khách lẻ</em>'}</strong></td>
        <td>${inv.employee_name || '--'}</td>
        <td class="text-center"><span class="badge badge-info">${inv.item_count} món</span></td>
        <td class="text-right text-muted">${app.formatCurrency(inv.subtotal)}</td>
        <td class="text-right ${inv.discount > 0 ? 'text-danger' : 'text-muted'}">${inv.discount > 0 ? '-' + app.formatCurrency(inv.discount) : '--'}</td>
        <td class="text-right bold text-primary">${app.formatCurrency(inv.total_amount)}</td>
        <td><span class="badge badge-success">${inv.payment_method}</span></td>
        <td>
          <button class="btn btn-sm btn-outline-primary" onclick="invoicesModule.viewDetail(${inv.id})">🧾 Xem / In</button>
        </td>
      </tr>
    `).join('');
  },

  async viewDetail(id) {
    try {
      const res = await api.get(`/api/invoices/${id}`);
      if (!res.success) return;
      const inv = res.data;

      posModule.showInvoiceModal(inv);
    } catch (err) {
      app.showToast('Không thể tải chi tiết hóa đơn', 'error');
    }
  }
};

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-invoice-filter')?.addEventListener('click', () => {
    invoicesModule.loadInvoices();
  });

  document.getElementById('btn-invoice-reset')?.addEventListener('click', () => {
    document.getElementById('filter-invoice-search').value = '';
    document.getElementById('filter-invoice-from').value = '';
    document.getElementById('filter-invoice-to').value = '';
    invoicesModule.loadInvoices();
  });

  document.getElementById('filter-invoice-search')?.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') invoicesModule.loadInvoices();
  });
});
