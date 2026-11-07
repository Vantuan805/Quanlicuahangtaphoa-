<%@ Page Title="Quản Lý Sản Phẩm" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Products.aspx.cs" Inherits="QuanLiCuaHangTapHoa.Products" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <!-- TOOLBAR & BỘ LỌC -->
    <div class="card mb-3">
        <div class="card-body p-3">
            <div class="d-flex justify-between align-center flex-wrap gap-2">
                <div class="d-flex align-center gap-2 flex-wrap flex-1">
                    <div class="search-input-group" style="max-width: 300px;">
                        <span class="search-icon">🔍</span>
                        <asp:TextBox ID="txtSearch" runat="server" placeholder="Tìm theo tên, mã, barcode..." CssClass="form-control" />
                    </div>

                    <asp:DropDownList ID="ddlCategoryFilter" runat="server" CssClass="form-control" style="max-width: 200px;">
                    </asp:DropDownList>

                    <div class="form-check d-flex align-center gap-1">
                        <asp:CheckBox ID="chkLowStockOnly" runat="server" Text="⚠️ Chỉ xem hàng sắp hết" />
                    </div>

                    <asp:Button ID="btnFilter" runat="server" Text="🔍 Lọc" CssClass="btn btn-secondary" OnClick="btnFilter_Click" />
                    <asp:Button ID="btnResetFilter" runat="server" Text="Làm mới" CssClass="btn btn-outline" OnClick="btnResetFilter_Click" />
                </div>

                <div>
                    <button type="button" class="btn btn-primary" onclick="openProductModal('add')">
                        ➕ Thêm sản phẩm mới
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- DANH SÁCH SẢN PHẨM -->
    <div class="card">
        <div class="card-header d-flex justify-between align-center">
            <h3>📦 Danh Sách Mặt Hàng (<asp:Literal ID="litTotalCount" runat="server" Text="0" />)</h3>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th class="text-center" style="width: 50px;">Icon</th>
                            <th>Mã SP</th>
                            <th>Barcode</th>
                            <th>Tên sản phẩm</th>
                            <th>Loại hàng</th>
                            <th>ĐVT</th>
                            <th class="text-right">Giá nhập</th>
                            <th class="text-right">Giá bán</th>
                            <th class="text-center">Tồn kho</th>
                            <th class="text-center">Định mức</th>
                            <th>Trạng thái</th>
                            <th class="text-center" style="width: 120px;">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptProducts" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td class="text-center" style="font-size: 20px;"><%# Eval("ImageIcon") %></td>
                                    <td><code><%# Eval("Code") %></code></td>
                                    <td><small class="text-muted"><%# Eval("Barcode") %></small></td>
                                    <td><strong><%# Eval("Name") %></strong></td>
                                    <td><span class="badge badge-secondary"><%# Eval("CategoryName") %></span></td>
                                    <td><%# Eval("Unit") %></td>
                                    <td class="text-right text-muted"><%# string.Format("{0:N0} ₫", Eval("CostPrice")) %></td>
                                    <td class="text-right bold text-primary"><%# string.Format("{0:N0} ₫", Eval("SellingPrice")) %></td>
                                    <td class="text-center bold <%# (int)Eval("StockQuantity") <= 5 ? "text-danger" : "" %>">
                                        <%# Eval("StockQuantity") %>
                                    </td>
                                    <td class="text-center text-muted"><%# Eval("MinStockAlert") %></td>
                                    <td>
                                        <span class="badge <%# Eval("StockBadgeClass") %>">
                                            <%# Eval("StockStatus") %>
                                        </span>
                                    </td>
                                    <td class="text-center">
                                        <button type="button" class="btn btn-sm btn-outline-primary"
                                                onclick='openEditModal(<%# Eval("Id") %>, "<%# Eval("Code") %>", "<%# Eval("Barcode") %>", "<%# (Eval("Name") ?? "").ToString().Replace("\"", "\\\"").Replace("'", "\\'") %>", <%# Eval("CategoryId") ?? 0 %>, <%# Eval("SupplierId") ?? 0 %>, "<%# Eval("Unit") %>", <%# Convert.ToInt64(Eval("CostPrice")) %>, <%# Convert.ToInt64(Eval("SellingPrice")) %>, <%# Eval("StockQuantity") %>, <%# Eval("MinStockAlert") %>, "<%# Eval("ImageIcon") %>")'>
                                            ✏️ Sửa
                                        </button>
                                        <asp:LinkButton ID="btnDelete" runat="server" CssClass="btn btn-sm btn-outline-danger"
                                            CommandArgument='<%# Eval("Id") %>' OnClick="btnDelete_Click"
                                            OnClientClick="return confirm('Bạn có chắc muốn xóa sản phẩm này?');">
                                            🗑️
                                        </asp:LinkButton>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- MODAL THÊM / SỬA SẢN PHẨM -->
    <div class="modal" id="product-modal">
        <div class="modal-backdrop" onclick="closeModal('product-modal')"></div>
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h3 id="modal-title">➕ Thêm Sản Phẩm Mới</h3>
                    <button type="button" class="modal-close" onclick="closeModal('product-modal')">✕</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfProductId" runat="server" Value="0" />
                    
                    <div class="form-row">
                        <div class="form-group col-6">
                            <label class="form-label">Tên sản phẩm: <span class="text-danger">*</span></label>
                            <asp:TextBox ID="txtProdName" runat="server" CssClass="form-control" placeholder="Nhập tên sản phẩm..." required="required" />
                        </div>
                        <div class="form-group col-6">
                            <label class="form-label">Mã vạch (Barcode):</label>
                            <asp:TextBox ID="txtProdBarcode" runat="server" CssClass="form-control" placeholder="Quét hoặc nhập barcode..." />
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group col-6">
                            <label class="form-label">Loại sản phẩm:</label>
                            <asp:DropDownList ID="ddlProdCategory" runat="server" CssClass="form-control">
                            </asp:DropDownList>
                        </div>
                        <div class="form-group col-6">
                            <label class="form-label">Nhà cung cấp:</label>
                            <asp:DropDownList ID="ddlProdSupplier" runat="server" CssClass="form-control">
                            </asp:DropDownList>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group col-4">
                            <label class="form-label">Đơn vị tính (ĐVT):</label>
                            <asp:TextBox ID="txtProdUnit" runat="server" CssClass="form-control" Text="Cái" placeholder="Gói, Lon, Chai, Hộp..." />
                        </div>
                        <div class="form-group col-4">
                            <label class="form-label">Giá nhập (Vốn):</label>
                            <asp:TextBox ID="txtProdCostPrice" runat="server" CssClass="form-control" TextMode="Number" Text="0" min="0" step="100" />
                        </div>
                        <div class="form-group col-4">
                            <label class="form-label">Giá bán:</label>
                            <asp:TextBox ID="txtProdSellingPrice" runat="server" CssClass="form-control" TextMode="Number" Text="0" min="0" step="100" required="required" />
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group col-4">
                            <label class="form-label">Tồn kho:</label>
                            <asp:TextBox ID="txtProdStock" runat="server" CssClass="form-control" TextMode="Number" Text="0" min="0" />
                        </div>
                        <div class="form-group col-4">
                            <label class="form-label">Mức cảnh báo tồn:</label>
                            <asp:TextBox ID="txtProdMinAlert" runat="server" CssClass="form-control" TextMode="Number" Text="10" min="0" />
                        </div>
                        <div class="form-group col-4">
                            <label class="form-label">Icon / Biểu tượng:</label>
                            <asp:TextBox ID="txtProdIcon" runat="server" CssClass="form-control" Text="📦" />
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('product-modal')">Hủy</button>
                    <asp:Button ID="btnSaveProduct" runat="server" Text="💾 Lưu Thông Tin" CssClass="btn btn-primary" OnClick="btnSaveProduct_Click" />
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        function openProductModal(mode) {
            document.getElementById('<%= hfProductId.ClientID %>').value = '0';
            document.getElementById('modal-title').textContent = '➕ Thêm Sản Phẩm Mới';
            document.getElementById('<%= txtProdName.ClientID %>').value = '';
            document.getElementById('<%= txtProdBarcode.ClientID %>').value = '';
            document.getElementById('<%= ddlProdCategory.ClientID %>').value = '0';
            document.getElementById('<%= ddlProdSupplier.ClientID %>').value = '0';
            document.getElementById('<%= txtProdUnit.ClientID %>').value = 'Cái';
            document.getElementById('<%= txtProdCostPrice.ClientID %>').value = '0';
            document.getElementById('<%= txtProdSellingPrice.ClientID %>').value = '0';
            document.getElementById('<%= txtProdStock.ClientID %>').value = '0';
            document.getElementById('<%= txtProdMinAlert.ClientID %>').value = '10';
            document.getElementById('<%= txtProdIcon.ClientID %>').value = '📦';
            openModal('product-modal');
        }

        function openEditModal(id, code, barcode, name, catId, supId, unit, cost, sell, stock, alert, icon) {
            document.getElementById('<%= hfProductId.ClientID %>').value = id;
            document.getElementById('modal-title').textContent = '✏️ Chỉnh Sửa Sản Phẩm: ' + name;
            document.getElementById('<%= txtProdName.ClientID %>').value = name;
            document.getElementById('<%= txtProdBarcode.ClientID %>').value = barcode || '';
            document.getElementById('<%= ddlProdCategory.ClientID %>').value = catId;
            document.getElementById('<%= ddlProdSupplier.ClientID %>').value = supId;
            document.getElementById('<%= txtProdUnit.ClientID %>').value = unit;
            document.getElementById('<%= txtProdCostPrice.ClientID %>').value = cost;
            document.getElementById('<%= txtProdSellingPrice.ClientID %>').value = sell;
            document.getElementById('<%= txtProdStock.ClientID %>').value = stock;
            document.getElementById('<%= txtProdMinAlert.ClientID %>').value = alert;
            document.getElementById('<%= txtProdIcon.ClientID %>').value = icon || '📦';
            openModal('product-modal');
        }
    </script>
</asp:Content>
