<%@ Page Title="Tổng quan & Thống kê" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="QuanLiCuaHangTapHoa.Default" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .chart-wrapper {
            width: 100%;
            height: 260px;
            position: relative;
        }
        #revenue-chart {
            width: 100%;
            height: 260px;
            display: block;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <!-- KPI Cards Grid -->
    <div class="kpi-grid">
        <div class="kpi-card card-revenue-today">
            <div class="kpi-icon">💰</div>
            <div class="kpi-details">
                <span class="kpi-title">Doanh thu hôm nay</span>
                <h3 class="kpi-value"><asp:Literal ID="litTodayRevenue" runat="server" Text="0 ₫" /></h3>
                <span class="kpi-sub"><asp:Literal ID="litTodayOrders" runat="server" Text="0 đơn hôm nay" /></span>
            </div>
        </div>

        <div class="kpi-card card-revenue-month">
            <div class="kpi-icon">📅</div>
            <div class="kpi-details">
                <span class="kpi-title">Doanh thu tháng này</span>
                <h3 class="kpi-value"><asp:Literal ID="litMonthRevenue" runat="server" Text="0 ₫" /></h3>
                <span class="kpi-sub"><asp:Literal ID="litGrossProfit" runat="server" Text="Lãi ước tính: 0 ₫" /></span>
            </div>
        </div>

        <div class="kpi-card card-sold">
            <div class="kpi-icon">🛍️</div>
            <div class="kpi-details">
                <span class="kpi-title">Sản phẩm đã bán</span>
                <h3 class="kpi-value"><asp:Literal ID="litSoldCount" runat="server" Text="0" /></h3>
                <span class="kpi-sub"><asp:Literal ID="litSoldToday" runat="server" Text="Hôm nay: 0 món" /></span>
            </div>
        </div>

        <div class="kpi-card card-inventory">
            <div class="kpi-icon">📦</div>
            <div class="kpi-details">
                <span class="kpi-title">Giá trị hàng tồn kho</span>
                <h3 class="kpi-value"><asp:Literal ID="litInventoryValue" runat="server" Text="0 ₫" /></h3>
                <span class="kpi-sub"><asp:Literal ID="litInventoryTotalUnits" runat="server" Text="Tổng tồn: 0 món" /></span>
            </div>
        </div>

        <div class="kpi-card card-orders">
            <div class="kpi-icon">🧾</div>
            <div class="kpi-details">
                <span class="kpi-title">Tổng số đơn hàng</span>
                <h3 class="kpi-value"><asp:Literal ID="litTotalOrders" runat="server" Text="0" /></h3>
                <span class="kpi-sub">Toàn thời gian</span>
            </div>
        </div>

        <div class="kpi-card card-customers">
            <div class="kpi-icon">👥</div>
            <div class="kpi-details">
                <span class="kpi-title">Tổng số khách hàng</span>
                <h3 class="kpi-value"><asp:Literal ID="litTotalCustomers" runat="server" Text="0" /></h3>
                <span class="kpi-sub">Khách thành viên</span>
            </div>
        </div>

        <div class="kpi-card card-alert">
            <div class="kpi-icon">⚠️</div>
            <div class="kpi-details">
                <span class="kpi-title">Sắp hết hàng</span>
                <h3 class="kpi-value text-danger"><asp:Literal ID="litLowStock" runat="server" Text="0" /></h3>
                <span class="kpi-sub">Cần nhập thêm</span>
            </div>
        </div>
    </div>

    <!-- Charts & Top Selling Section -->
    <div class="dashboard-grid-2">
        <!-- Canvas Revenue Chart -->
        <div class="card dashboard-card">
            <div class="card-header">
                <h3>📈 Biểu đồ Doanh thu 7 ngày gần nhất</h3>
                <span class="badge badge-info">Tự động cập nhật</span>
            </div>
            <div class="card-body">
                <div class="chart-wrapper">
                    <canvas id="revenue-chart"></canvas>
                </div>
            </div>
        </div>

        <!-- Top Selling Products -->
        <div class="card dashboard-card">
            <div class="card-header">
                <h3>🔥 Sản phẩm bán chạy nhất</h3>
                <span class="badge badge-success">Top theo số lượng</span>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Sản phẩm</th>
                                <th>ĐVT</th>
                                <th class="text-right">Đã bán</th>
                                <th class="text-right">Doanh thu</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rptTopSelling" runat="server">
                                <ItemTemplate>
                                    <tr>
                                        <td><%# Container.ItemIndex + 1 %></td>
                                        <td><strong><%# Eval("ProductName") %></strong></td>
                                        <td><span class="badge badge-secondary"><%# Eval("Unit") %></span></td>
                                        <td class="text-right bold text-primary"><%# Eval("TotalSold") %></td>
                                        <td class="text-right bold"><%# string.Format("{0:N0} ₫", Eval("TotalRevenue")) %></td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Low Stock Warning & Recent Invoices -->
    <div class="dashboard-grid-2">
        <!-- Cảnh báo sản phẩm sắp hết hàng -->
        <div class="card dashboard-card">
            <div class="card-header header-warning">
                <h3>⚠️ Cảnh báo: Sản phẩm sắp hết hàng</h3>
                <a href="GoodsReceipts.aspx" class="btn btn-sm btn-primary">➕ Lập phiếu nhập</a>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Mã SP</th>
                                <th>Tên sản phẩm</th>
                                <th>Loại hàng</th>
                                <th class="text-center">Tồn kho</th>
                                <th class="text-center">Định mức</th>
                                <th>Trạng thái</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rptLowStock" runat="server">
                                <ItemTemplate>
                                    <tr>
                                        <td><code><%# Eval("Code") %></code></td>
                                        <td><strong><%# Eval("Name") %></strong></td>
                                        <td><%# Eval("CategoryName") %></td>
                                        <td class="text-center bold text-danger"><%# Eval("StockQuantity") %> <%# Eval("Unit") %></td>
                                        <td class="text-center"><%# Eval("MinStockAlert") %></td>
                                        <td>
                                            <span class="badge <%# (int)Eval("StockQuantity") <= 0 ? "badge-danger" : "badge-warning" %>">
                                                <%# (int)Eval("StockQuantity") <= 0 ? "Hết hàng" : "Sắp hết" %>
                                            </span>
                                        </td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- Hóa đơn gần nhất -->
        <div class="card dashboard-card">
            <div class="card-header">
                <h3>🧾 Hóa đơn bán lẻ gần đây</h3>
                <a href="Invoices.aspx" class="btn btn-sm btn-outline">Xem tất cả</a>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Mã HĐ</th>
                                <th>Khách hàng</th>
                                <th>Thời gian</th>
                                <th>Hình thức</th>
                                <th class="text-right">Tổng tiền</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rptRecentInvoices" runat="server">
                                <ItemTemplate>
                                    <tr>
                                        <td><code><%# Eval("Code") %></code></td>
                                        <td><%# Eval("CustomerName") %></td>
                                        <td><%# string.Format("{0:HH:mm dd/MM}", Eval("InvoiceDate")) %></td>
                                        <td><span class="badge badge-info"><%# Eval("PaymentMethod") %></span></td>
                                        <td class="text-right bold text-success"><%# string.Format("{0:N0} ₫", Eval("TotalAmount")) %></td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        var chartData = <%= ChartDataJson %>;

        function drawRevenueChart(items) {
            const canvas = document.getElementById('revenue-chart');
            if (!canvas) return;
            const ctx = canvas.getContext('2d');

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

            const padding = { top: 30, right: 25, bottom: 40, left: 75 };
            const chartW = width - padding.left - padding.right;
            const chartH = height - padding.top - padding.bottom;

            const maxRev = Math.max(...items.map(i => Number(i.Revenue) || 0), 100000);
            const niceMax = Math.ceil(maxRev / 100000) * 100000;

            // Grid lines
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

                let label = (yVal >= 1000000) ? (yVal / 1000000).toFixed(1) + 'M' : (yVal / 1000).toFixed(0) + 'k';
                ctx.fillText(label, padding.left - 8, y);
            }

            const stepX = chartW / (items.length - 1 || 1);
            const points = items.map((item, idx) => {
                const val = Number(item.Revenue) || 0;
                const x = padding.left + idx * stepX;
                const y = padding.top + chartH - (val / niceMax) * chartH;
                return { x, y, val, label: item.Label };
            });

            // Gradient Fill
            const grad = ctx.createLinearGradient(0, padding.top, 0, padding.top + chartH);
            grad.addColorStop(0, 'rgba(16, 185, 129, 0.35)');
            grad.addColorStop(1, 'rgba(16, 185, 129, 0.02)');

            ctx.beginPath();
            ctx.moveTo(points[0].x, padding.top + chartH);
            points.forEach(p => ctx.lineTo(p.x, p.y));
            ctx.lineTo(points[points.length - 1].x, padding.top + chartH);
            ctx.closePath();
            ctx.fillStyle = grad;
            ctx.fill();

            // Line
            ctx.beginPath();
            ctx.strokeStyle = '#10b981';
            ctx.lineWidth = 3;
            points.forEach((p, idx) => {
                if (idx === 0) ctx.moveTo(p.x, p.y);
                else ctx.lineTo(p.x, p.y);
            });
            ctx.stroke();

            // Dots & X-Labels
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';
            points.forEach(p => {
                ctx.beginPath();
                ctx.arc(p.x, p.y, 4, 0, Math.PI * 2);
                ctx.fillStyle = '#ffffff';
                ctx.fill();
                ctx.strokeStyle = '#10b981';
                ctx.lineWidth = 2;
                ctx.stroke();

                ctx.fillStyle = '#475569';
                ctx.fillText(p.label, p.x, padding.top + chartH + 10);
            });
        }

        window.addEventListener('load', function () {
            drawRevenueChart(chartData);
        });
        window.addEventListener('resize', function () {
            drawRevenueChart(chartData);
        });
    </script>
</asp:Content>
