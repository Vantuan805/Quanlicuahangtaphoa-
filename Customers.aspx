<%@ Page Title="Quản Lý Khách Hàng" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Customers.aspx.cs" Inherits="QuanLiCuaHangTapHoa.Customers" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <!-- TOOLBAR & TÌM KIẾM -->
    <div class="card mb-3">
        <div class="card-body p-3">
            <div class="d-flex justify-between align-center flex-wrap gap-2">
                <div class="d-flex align-center gap-2 flex-wrap flex-1">
                    <div class="search-input-group" style="max-width: 320px;">
                        <span class="search-icon">🔍</span>
                        <asp:TextBox ID="txtSearch" runat="server" placeholder="Tìm theo tên, số điện thoại, mã..." CssClass="form-control" />
                    </div>
                    <asp:Button ID="btnSearch" runat="server" Text="🔍 Tìm kiếm" CssClass="btn btn-secondary" OnClick="btnSearch_Click" />
                    <asp:Button ID="btnReset" runat="server" Text="Làm mới" CssClass="btn btn-outline" OnClick="btnReset_Click" />
                </div>
                <div>
                    <button type="button" class="btn btn-primary" onclick="openCustomerModal('add')">
                        ➕ Thêm khách hàng mới
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- DANH SÁCH KHÁCH HÀNG -->
    <div class="card">
        <div class="card-header d-flex justify-between align-center">
            <h3>👥 Danh Sách Khách Hàng Thân Thiết (<asp:Literal ID="litCount" runat="server" Text="0" />)</h3>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th style="width: 80px;">Mã</th>
                            <th>Họ và tên</th>
                            <th>Số điện thoại</th>
                            <th>Địa chỉ</th>
                            <th class="text-center">Điểm tích lũy</th>
                            <th class="text-right">Tổng chi tiêu</th>
                            <th>Ngày tham gia</th>
                            <th class="text-center" style="width: 140px;">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptCustomers" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><code><%# Eval("Code") %></code></td>
                                    <td><strong><%# Eval("Name") %></strong></td>
                                    <td><span class="badge badge-secondary">📞 <%# Eval("Phone") %></span></td>
                                    <td><%# Eval("Address") %></td>
                                    <td class="text-center">
                                        <span class="badge badge-warning">⭐ <%# Eval("Points") %> điểm</span>
                                    </td>
                                    <td class="text-right bold text-success"><%# string.Format("{0:N0} ₫", Eval("TotalSpent")) %></td>
                                    <td><%# string.Format("{0:dd/MM/yyyy}", Eval("CreatedAt")) %></td>
                                    <td class="text-center">
                                        <button type="button" class="btn btn-sm btn-outline-primary"
                                                onclick='openEditCustomerModal(<%# Eval("Id") %>, "<%# Eval("Code") %>", "<%# (Eval("Name") ?? "").ToString().Replace("\"", "\\\"").Replace("'", "\\'") %>", "<%# Eval("Phone") %>", "<%# (Eval("Address") ?? "").ToString().Replace("\"", "\\\"").Replace("'", "\\'") %>")'>
                                            ✏️ Sửa
                                        </button>
                                        <asp:LinkButton ID="btnDelete" runat="server" CssClass="btn btn-sm btn-outline-danger"
                                            CommandArgument='<%# Eval("Id") %>' OnClick="btnDelete_Click"
                                            OnClientClick="return confirm('Bạn có chắc muốn xóa khách hàng này?');">
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

    <!-- MODAL KHÁCH HÀNG -->
    <div class="modal" id="cust-modal">
        <div class="modal-backdrop" onclick="closeModal('cust-modal')"></div>
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3 id="cust-modal-title">➕ Thêm Khách Hàng Mới</h3>
                    <button type="button" class="modal-close" onclick="closeModal('cust-modal')">✕</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfCustId" runat="server" Value="0" />
                    <div class="form-group">
                        <label class="form-label">Họ và tên khách hàng: <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtCustName" runat="server" CssClass="form-control" placeholder="Ví dụ: Nguyễn Thị Lan..." required="required" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Số điện thoại: <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtCustPhone" runat="server" CssClass="form-control" placeholder="090... hoặc 098..." required="required" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Địa chỉ:</label>
                        <asp:TextBox ID="txtCustAddress" runat="server" CssClass="form-control" placeholder="Số nhà, đường, phường, quận..." />
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('cust-modal')">Hủy</button>
                    <asp:Button ID="btnSaveCustomer" runat="server" Text="💾 Lưu Thông Tin" CssClass="btn btn-primary" OnClick="btnSaveCustomer_Click" />
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        function openCustomerModal(mode) {
            document.getElementById('<%= hfCustId.ClientID %>').value = '0';
            document.getElementById('cust-modal-title').textContent = '➕ Thêm Khách Hàng Mới';
            document.getElementById('<%= txtCustName.ClientID %>').value = '';
            document.getElementById('<%= txtCustPhone.ClientID %>').value = '';
            document.getElementById('<%= txtCustAddress.ClientID %>').value = '';
            openModal('cust-modal');
        }

        function openEditCustomerModal(id, code, name, phone, address) {
            document.getElementById('<%= hfCustId.ClientID %>').value = id;
            document.getElementById('cust-modal-title').textContent = '✏️ Chỉnh Sửa KH: ' + name;
            document.getElementById('<%= txtCustName.ClientID %>').value = name;
            document.getElementById('<%= txtCustPhone.ClientID %>').value = phone || '';
            document.getElementById('<%= txtCustAddress.ClientID %>').value = address || '';
            openModal('cust-modal');
        }
    </script>
</asp:Content>
