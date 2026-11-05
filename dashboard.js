// Dashboard & Statistics Controller
const dashboardModule = {
  async loadDashboard() {
    try {
      const res = await api.get('/api/dashboard');
      if (!res.success) return;
      const data = res.data;

      // 1. KPI Cards
      document.getElementById('kpi-today-revenue').textContent = app.formatCurrency(data.todayRevenue);
      document.getElementById('kpi-today-orders').textContent = `${data.todayOrders} đơn hôm nay`;
      document.getElementById('kpi-month-revenue').textContent = app.formatCurrency(data.monthRevenue);
      document.getElementById('kpi-gross-profit').textContent = `Lãi ước tính: ${app.formatCurrency(data.grossProfit)}`;
      document.getElementById('kpi-sold-count').textContent = Number(data.soldProductsCount).toLocaleString('vi-VN');
      document.getElementById('kpi-sold-today').textContent = `Hôm nay: ${data.soldProductsToday} món`;
      document.getElementById('kpi-inv-value').textContent = app.formatCurrency(data.inventoryValue);
      document.getElementById('kpi-inv-units').textContent = `Tổng tồn: ${Number(data.inventoryTotalUnits).toLocaleString('vi-VN')} món`;
      document.getElementById('kpi-total-orders').textContent = data.totalOrders;
      document.getElementById('kpi-total-customers').textContent = data.totalCustomers;
      document.getElementById('kpi-low-stock').textContent = data.lowStockCount;

      // Topbar & sidebar badges
      const topbarLow = document.getElementById('topbar-low-count');
      if (topbarLow) topbarLow.textContent = data.lowStockCount;
      const sidebarLow = document.getElementById('sidebar-low-badge');
      if (sidebarLow) {
        sidebarLow.textContent = data.lowStockCount;
        sidebarLow.style.display = data.lowStockCount > 0 ? 'inline-flex' : 'none';
      }

      // 2. Draw 7-Day Revenue Canvas Chart
      this.drawRevenueChart(data.revenueLast7Days || []);

      // 3. Render Top Selling Products
      this.renderTopSelling(data.topSelling || []);

      // 4. Render Low Stock Products
      this.renderLowStock(data.lowStockProducts || []);

      // 5. Render Recent Invoices
      this.renderRecentInvoices(data.recentInvoices || []);

    } catch (err) {
      console.error('Failed to load dashboard:', err);
      app.showToast('Lỗi khi tải dữ liệu tổng quan', 'error');
    }
  },

  // Draw pure HTML5 Canvas Revenue Chart
  drawRevenueChart(items) {
    const canvas = document.getElementById('revenue-chart');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    // High DPI Canvas support
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();
    const width = rect.width || 600;
    const height = 260;

    canvas.width = width * dpr;
    canvas.height = height * dpr;
    ctx.scale(dpr, dpr);

    ctx.clearRect(0, 0, width, height);

    if (!items || items.length === 0) {
      ctx.fillStyle = '#94a3b8';
      ctx.font = '14px Inter, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('Chưa có dữ liệu doanh thu', width / 2, height / 2);
      return;
    }

    const padding = { top: 30, right: 25, bottom: 40, left: 65 };
    const chartW = width - padding.left - padding.right;
    const chartH = height - padding.top - padding.bottom;

    const maxRev = Math.max(...items.map(i => Number(i.revenue) || 0), 100000);
    // Round maxRev up nicely
    const niceMax = Math.ceil(maxRev / 100000) * 100000;

    // Draw horizontal grid lines & labels
    const gridLines = 4;
    ctx.strokeStyle = '#e2e8f0';
    ctx.lineWidth = 1;
    ctx.fillStyle = '#64748b';
    ctx.font = '11px Inter, sans-serif';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';

    for (let i = 0; i <= gridLines; i++) {
      const yVal = (niceMax / gridLines) * i;
      const y = padding.top + chartH - (i / gridLines) * chartH;

      ctx.beginPath();
      ctx.moveTo(padding.left, y);
      ctx.lineTo(width - padding.right, y);
      ctx.stroke();

      // Format currency label (e.g., 200k)
      let label = yVal >= 1000000 ? (yVal / 1000000).toFixed(1) + 'tr' : (yVal / 1000) + 'k';
      if (yVal === 0) label = '0';
      ctx.fillText(label, padding.left - 10, y);
    }

    // Draw bars
    const barWidth = Math.min(42, (chartW / items.length) * 0.55);
    const step = chartW / items.length;

    items.forEach((item, idx) => {
      const rev = Number(item.revenue) || 0;
      const barH = (rev / niceMax) * chartH;
      const x = padding.left + idx * step + (step - barWidth) / 2;
      const y = padding.top + chartH - barH;

      // Gradient fill for bars
      const grad = ctx.createLinearGradient(0, y, 0, y + barH);
      grad.addColorStop(0, '#10b981');
      grad.addColorStop(1, '#059669');

      ctx.fillStyle = grad;
      // Draw rounded top bar
      const radius = 6;
      ctx.beginPath();
      ctx.moveTo(x, y + barH);
      ctx.lineTo(x, y + radius);
      ctx.quadraticCurveTo(x, y, x + radius, y);
      ctx.lineTo(x + barWidth - radius, y);
      ctx.quadraticCurveTo(x + barWidth, y, x + barWidth, y + radius);
      ctx.lineTo(x + barWidth, y + barH);
      ctx.closePath();
      ctx.fill();

      // Bar Value on top if > 0
      if (rev > 0) {
        ctx.fillStyle = '#065f46';
        ctx.font = 'bold 11px Inter, sans-serif';
        ctx.textAlign = 'center';
        let shortText = rev >= 1000000 ? (rev / 1000000).toFixed(1) + 'M' : (rev / 1000).toFixed(0) + 'k';
        ctx.fillText(shortText, x + barWidth / 2, y - 8);
      }

      // X-axis label (date)
      ctx.fillStyle = '#475569';
      ctx.font = '11px Inter, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(item.label || item.date, x + barWidth / 2, height - padding.bottom + 18);
    });
  },

  renderTopSelling(items) {
    const tbody = document.getElementById('top-selling-tbody');
    if (!tbody) return;

    if (items.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted">Chưa có sản phẩm nào được bán</td></tr>';
      return;
    }

    tbody.innerHTML = items.map((p, index) => `
      <tr>
        <td class="bold text-muted">${index + 1}</td>
        <td><strong>${p.product_name}</strong></td>
        <td><span class="badge badge-info">${p.unit}</span></td>
        <td class="text-right bold text-primary">${p.total_sold}</td>
        <td class="text-right bold">${app.formatCurrency(p.total_revenue)}</td>
      </tr>
    `).join('');
  },

  renderLowStock(items) {
    const tbody = document.getElementById('dashboard-lowstock-tbody');
    if (!tbody) return;

    if (items.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center text-success py-3">🎉 Tất cả sản phẩm đều đủ hàng tồn kho!</td></tr>';
      return;
    }

    tbody.innerHTML = items.map(p => {
      const isOut = p.stock_quantity <= 0;
      const statusBadge = isOut 
        ? '<span class="badge badge-danger">Hết hàng</span>'
        : '<span class="badge badge-warning">Sắp hết hàng</span>';

      return `
        <tr>
          <td><code>${p.code}</code></td>
          <td><strong>${p.name}</strong></td>
          <td>${p.category_name || '--'}</td>
          <td class="text-center bold ${isOut ? 'text-danger' : 'text-danger'}">${p.stock_quantity} ${p.unit}</td>
          <td class="text-center text-muted">${p.min_stock_alert} ${p.unit}</td>
          <td>${statusBadge}</td>
        </tr>
      `;
    }).join('');
  },

  renderRecentInvoices(items) {
    const tbody = document.getElementById('dashboard-recent-invoices-tbody');
    if (!tbody) return;

    if (items.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted">Chưa có hóa đơn nào</td></tr>';
      return;
    }

    tbody.innerHTML = items.map(inv => `
      <tr>
        <td><code>${inv.code}</code></td>
        <td class="text-muted" style="font-size: 0.8rem;">${app.formatDateTime(inv.invoice_date)}</td>
        <td>${inv.customer_name || '<em class="text-muted">Khách lẻ</em>'}</td>
        <td class="text-right bold text-primary">${app.formatCurrency(inv.total_amount)}</td>
        <td><span class="badge badge-success">${inv.payment_method}</span></td>
      </tr>
    `).join('');
  }
};
