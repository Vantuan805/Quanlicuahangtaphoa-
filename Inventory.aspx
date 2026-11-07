<%@ Page Title="Quản Lý Kho Hàng & Kiểm Kê" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Inventory.aspx.cs" Inherits="QuanLiCuaHangTapHoa.Inventory" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <!-- KPI THỐNG KÊ KHO HÀNG -->
    <div class="kpi-grid mb-3">
        <div class="kpi-card card-inventory">
            <div class="kpi-icon">📦</div>
            <div class="kpi-details">
                <span class="kpi-title">Tổng số mặt hàng</span>
                <h3 class="kpi-value"><asp:Literal ID="litTotalProducts" runat="server" Text="0" /></h3>
                <span class="kpi-sub">Danh mục kinh doanh</span>
            </div>
        </div>

        <div class="kpi-card card-sold">
            <div class="kpi-icon">🔢</div>
            <div class="kpi-details">
                <span class="kpi-title">Tổng số đơn vị tồn</span>
                <h3 class="kpi-value"><asp:Literal ID="litTotalUnits" runat="server" Text="0" /></h3>
                <span class="kpi-sub">Gói, lon, chai, hộp...</span>
            </div>
        </div>

        <div class="kpi-card card-revenue-today">
            <div class="kpi-icon">💰</div>
            <div class="kpi-details">
                <span class="kpi-title">Tổng giá trị vốn tồn kho</span>
                <h3 class="kpi-value"><asp:Literal ID="litTotalValue" runat="server" Text="0 ₫" /></h3>
                <span class="kpi-sub">Tính theo giá vốn nhập</span>
            </div>
        </div>

        <div class="kpi-card card-alert">
            <div class="kpi-icon">⚠️</div>
            <div class="kpi-details">
                <span class="kpi-title">Mặt hàng sắp hết</span>
                <h3 class="kpi-value text-danger"><asp:Literal ID="litLowCount" runat="server" Text="0" /></h3>
                <span class="kpi-sub">Cần nhập bổ sung</span>
            </div>
        </div>

        <div class="kpi-card card-revenue-month">
            <div class="kpi-icon">❌</div>
            <div class="kpi-details">
                <span class="kpi-title">Mặt hàng đã hết</span>
                <h3 class="kpi-value text-danger"><asp:Literal ID="litOutCount" runat="server" Text="0" /></h3>
                <span class="kpi-sub">Tồn bằng 0</span>
            </div>
        </div>
    </div>

    <!-- TOOLBAR & BỘ LỌC KHO -->
    <div class="card mb-3">
        <div class="card-body p-3">
            <div class="d-flex justify-between align-center flex-wrap gap-2">
                <div class="d-flex align-center gap-2 flex-wrap flex-1">
                    <div class="search-input-group" style="max-width: 280px;">
                        <span class="search-icon">🔍</span>
                        <asp:TextBox ID="txtSearch" runat="server" placeholder="Tìm theo tên sản phẩm, mã SP..." CssClass="form-control" />
                    </div>

                    <asp:DropDownList ID="ddlStatusFilter" runat="server" CssClass="form-control" style="max-width: 200px;">
                        <asp:ListItem Text="Tất cả trạng thái" Value="all" Selected="True" />
                        <asp:ListItem Text="⚠️ Sắp hết hàng" Value="low" />
                        <asp:ListItem Text="❌ Đã hết hàng" Value="out" />
                        <asp:ListItem Text="✅ Còn hàng tốt" Value="normal" />
                    </asp:DropDownList>

                    <asp:Button ID="btnFilter" runat="server" Text="🔍 Lọc" CssClass="btn btn-secondary" OnClick="btnFilter_Click" />
                    <asp:Button ID="btnReset" runat="server" Text="Làm mới" CssClass="btn btn-outline" OnClick="btnReset_Click" />
                </div>

                <div>
                    <button type="button" class="btn btn-primary" onclick="openAdjustModal(0, '', 0, '')">
                        📝 Phiếu Kiểm Kê Kho
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- BẢNG TỒN KHO SẢN PHẨM -->
    <div class="card mb-4">
        <div class="card-header d-flex justify-between align-center">
            <h3>🏢 Trạng Thái Tồn Kho Thực Tế (<asp:Literal ID="litFilteredCount" runat="server" Text="0" />)</h3>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th style="width: 50px;" class="text-center">Icon</th>
                            <th>Mã SP</th>
                            <th>Tên sản phẩm</th>
                            <th>Loại hàng</th>
                            <th class="text-center">Tồn kho</th>
                            <th class="text-center">Định mức</th>
                            <th class="text-right">Giá vốn</th>
                            <th class="text-right">Giá trị tồn</th>
                            <th>Trạng thái</th>
                            <th class="text-center" style="width: 120px;">Kiểm kê</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptInventory" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td class="text-center" style="font-size: 20px;"><%# Eval("ImageIcon") %></td>
                                    <td><code><%# Eval("Code") %></code></td>
                                    <td><strong><%# Eval("Name") %></strong></td>
                                    <td><span class="badge badge-secondary"><%# Eval("CategoryName") %></span></td>
                                    <td class="text-center bold <%# (int)Eval("StockQuantity") <= 5 ? "text-danger" : "" %>">
                                        <%# Eval("StockQuantity") %> <%# Eval("Unit") %>
                                    </td>
                                    <td class="text-center text-muted"><%# Eval("MinStockAlert") %></td>
                                    <td class="text-right text-muted"><%# string.Format("{0:N0} ₫", Eval("CostPrice")) %></td>
                                    <td class="text-right bold text-primary"><%# string.Format("{0:N0} ₫", Eval("InventoryValue")) %></td>
                                    <td>
                                        <span class="badge <%# Eval("StockBadgeClass") %>">
                                            <%# Eval("StockStatus") %>
                                        </span>
                                    </td>
                                    <td class="text-center">
                                        <button type="button" class="btn btn-sm btn-outline-warning"
                                                onclick='openAdjustModal(<%# Eval("Id") %>, "<%# (Eval("Name") ?? "").ToString().Replace("\"", "\\\"").Replace("'", "\\'") %>", <%# Eval("StockQuantity") %>, "<%# Eval("Unit") %>")'>
                                            ⚖️ Kiểm kê
                                        </button>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- LỊCH SỬ ĐIỀU CHỈNH / KIỂM KÊ -->
    <div class="card">
        <div class="card-header">
            <h3>📋 Lịch Sử Kiểm Kê & Điều Chỉnh Tồn Kho Gần Đây</h3>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th style="width: 100px;">Mã phiếu</th>
                            <th>Thời gian</th>
                            <th>Sản phẩm</th>
                            <th class="text-center">Tồn cũ</th>
                            <th class="text-center">Tồn mới</th>
                            <th class="text-center">Chênh lệch</th>
                            <th>Lý do điều chỉnh</th>
                            <th>Nhân viên kiểm kê</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptAdjustments" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><code><%# Eval("Code") %></code></td>
                                    <td><%# string.Format("{0:HH:mm dd/MM/yyyy}", Eval("AdjustedAt")) %></td>
                                    <td><strong><%# Eval("ProductName") %></strong></td>
                                    <td class="text-center"><%# Eval("OldQuantity") %> <%# Eval("Unit") %></td>
                                    <td class="text-center bold"><%# Eval("NewQuantity") %> <%# Eval("Unit") %></td>
                                    <td class="text-center bold <%# (int)Eval("ChangeQuantity") < 0 ? "text-danger" : "text-success" %>">
                                        <%# (int)Eval("ChangeQuantity") > 0 ? "+" + Eval("ChangeQuantity") : Eval("ChangeQuantity") %>
                                    </td>
                                    <td><%# Eval("Reason") %></td>
                                    <td><span class="badge badge-secondary"><%# Eval("EmployeeName") %></span></td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- MODAL KIỂM KÊ KHO -->
    <div class="modal" id="adjust-modal">
        <div class="modal-backdrop" onclick="closeModal('adjust-modal')"></div>
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>⚖️ Điều Chỉnh & Kiểm Kê Tồn Kho</h3>
                    <button type="button" class="modal-close" onclick="closeModal('adjust-modal')">✕</button>
                </div>
                <div class="modal-body">
                    <div class="form-group" id="grp-select-prod">
                        <label class="form-label">Chọn sản phẩm cần kiểm kê: <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="ddlModalProducts" runat="server" CssClass="form-control" onchange="onModalProductChange(this)">
                        </asp:DropDownList>
                    </div>

                    <div class="p-3 mb-3" style="background:#f1f5f9; border-radius:var(--radius-sm);">
                        <div>Tên sản phẩm: <strong id="adj-prod-name">---</strong></div>
                        <div>Số lượng hệ thống hiện tại: <strong class="text-primary" id="adj-current-stock">0</strong> <span id="adj-prod-unit"></span></div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Số lượng thực tế đếm được: <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtNewQuantity" runat="server" CssClass="form-control" TextMode="Number" min="0" oninput="calculateStockDiff()" />
                        <small class="text-muted" id="adj-diff-text">Chênh lệch: 0</small>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Lý do điều chỉnh: <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="ddlReason" runat="server" CssClass="form-control">
                            <asp:ListItem Text="Kiểm kê định kỳ" Value="Kiểm kê định kỳ" Selected="True" />
                            <asp:ListItem Text="Hao hụt / Rơi vỡ / Hỏng hóc" Value="Hao hụt / Rơi vỡ / Hỏng hóc" />
                            <asp:ListItem Text="Hết hạn sử dụng (Hủy hàng)" Value="Hết hạn sử dụng (Hủy hàng)" />
                            <asp:ListItem Text="Tìm thấy hàng thất lạc" Value="Tìm thấy hàng thất lạc" />
                            <asp:ListItem Text="Sai sót khi nhập hàng" Value="Sai sót khi nhập hàng" />
                            <asp:ListItem Text="Khác" Value="Khác" />
                        </asp:DropDownList>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Nhân viên thực hiện:</label>
                        <asp:DropDownList ID="ddlModalEmployees" runat="server" CssClass="form-control">
                        </asp:DropDownList>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('adjust-modal')">Hủy</button>
                    <asp:Button ID="btnSaveAdjust" runat="server" Text="💾 Lưu Kết Quả Kiểm Kê" CssClass="btn btn-primary" OnClick="btnSaveAdjust_Click" />
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        var currentSelectedStock = 0;

        function openAdjustModal(id, name, stock, unit) {
            const ddl = document.getElementById('<%= ddlModalProducts.ClientID %>');
            if (id > 0) {
                ddl.value = id;
                document.getElementById('adj-prod-name').textContent = name;
                document.getElementById('adj-current-stock').textContent = stock;
                document.getElementById('adj-prod-unit').textContent = unit;
                document.getElementById('<%= txtNewQuantity.ClientID %>').value = stock;
                currentSelectedStock = stock;
            } else {
                if (ddl.options.length > 0) {
                    ddl.selectedIndex = 0;
                    onModalProductChange(ddl);
                }
            }
            calculateStockDiff();
            openModal('adjust-modal');
        }

        function onModalProductChange(selectEl) {
            const opt = selectEl.options[selectEl.selectedIndex];
            if (opt && opt.value) {
                const stock = parseInt(opt.dataset.stock) || 0;
                const unit = opt.dataset.unit || '';
                document.getElementById('adj-prod-name').textContent = opt.text;
                document.getElementById('adj-current-stock').textContent = stock;
                document.getElementById('adj-prod-unit').textContent = unit;
                document.getElementById('<%= txtNewQuantity.ClientID %>').value = stock;
                currentSelectedStock = stock;
            }
            calculateStockDiff();
        }

        function calculateStockDiff() {
            const newQty = parseInt(document.getElementById('<%= txtNewQuantity.ClientID %>').value) || 0;
            const diff = newQty - currentSelectedStock;
            const diffEl = document.getElementById('adj-diff-text');
            if (diff > 0) {
                diffEl.textContent = `Chênh lệch: +${diff} (Thừa hàng)`;
                diffEl.className = 'bold text-success';
            } else if (diff < 0) {
                diffEl.textContent = `Chênh lệch: ${diff} (Thiếu hàng / Hao hụt)`;
                diffEl.className = 'bold text-danger';
            } else {
                diffEl.textContent = 'Chênh lệch: 0 (Khớp số lượng)';
                diffEl.className = 'text-muted';
            }
        }
    </script>
</asp:Content>
