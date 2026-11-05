// Reports & Business Analytics Module
const reportsModule = {
  async loadReports() {
    try {
      const res = await api.get('/api/reports');
      if (res.success) {
        this.renderCategoryReport(res.data.categorySales || []);
        this.renderPaymentReport(res.data.paymentMethods || []);
        this.renderTopProductsReport(res.data.topProducts || []);
      }
    } catch (err) {
      console.error('Failed to load reports:', err);
      app.showToast('Lỗi khi tải báo cáo kinh doanh', 'error');
    }
  },

  renderCategoryReport(categories) {
    const tbody = document.getElementById('reports-category-tbody');
    if (!tbody) return;

    if (categories.length === 0) {
      tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted">Chưa có dữ liệu</td></tr>';
      return;
    }

    const totalRev = categories.reduce((sum, c) => sum + (Number(c.revenue) || 0), 0);

    tbody.innerHTML = categories.map(c => {
      const rev = Number(c.revenue) || 0;
      const share = totalRev > 0 ? ((rev / totalRev) * 100).toFixed(1) : 0;

      return `
        <tr>
          <td><strong>${c.name}</strong></td>
          <td class="text-center bold">${c.units_sold || 0}</td>
          <td class="text-right bold text-primary">${app.formatCurrency(rev)}</td>
          <td class="text-right">
            <span class="badge ${share > 20 ? 'badge-success' : 'badge-info'}">${share}%</span>
          </td>
        </tr>
      `;
    }).join('');
  },

  renderPaymentReport(methods) {
    const tbody = document.getElementById('reports-payment-tbody');
    if (!tbody) return;

    if (methods.length === 0) {
      tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted">Chưa có dữ liệu</td></tr>';
      return;
    }

    const totalMoney = methods.reduce((sum, m) => sum + (Number(m.total) || 0), 0);

    tbody.innerHTML = methods.map(m => {
      const tot = Number(m.total) || 0;
      const share = totalMoney > 0 ? ((tot / totalMoney) * 100).toFixed(1) : 0;

      return `
        <tr>
          <td><strong>${m.payment_method}</strong></td>
          <td class="text-center">${m.count} đơn</td>
          <td class="text-right bold text-primary">${app.formatCurrency(tot)}</td>
          <td class="text-right"><span class="badge badge-info">${share}%</span></td>
        </tr>
      `;
    }).join('');
  },

  renderTopProductsReport(products) {
    const tbody = document.getElementById('reports-topprods-tbody');
    if (!tbody) return;

    if (products.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted">Chưa có dữ liệu bán lẻ</td></tr>';
      return;
    }

    tbody.innerHTML = products.map((p, idx) => `
      <tr>
        <td class="bold text-muted">${idx + 1}</td>
        <td><code>${p.code}</code></td>
        <td>
          <span style="font-size: 1.2rem; margin-right: 4px;">${p.image_icon || '📦'}</span>
          <strong>${p.name}</strong>
        </td>
        <td><span class="badge badge-info">${p.unit}</span></td>
        <td class="text-center bold text-primary">${p.total_sold}</td>
        <td class="text-right bold">${app.formatCurrency(p.total_revenue)}</td>
        <td class="text-right bold text-success">${app.formatCurrency(p.total_profit)}</td>
      </tr>
    `).join('');
  }
};
