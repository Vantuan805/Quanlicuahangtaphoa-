<%@ Page Title="Quản Lý Nhà Cung Cấp" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Suppliers.aspx.cs" Inherits="QuanLiCuaHangTapHoa.Suppliers" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="card">
        <div class="card-header d-flex justify-between align-center">
            <h3>🏭 Danh Sách Nhà Cung Cấp (<asp:Literal ID="litCount" runat="server" Text="0" />)</h3>
            <button type="button" class="btn btn-primary" onclick="openSupplierModal('add')">
                ➕ Thêm đối tác mới
            </button>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th style="width: 80px;">Mã</th>
                            <th>Tên nhà cung cấp / Công ty</th>
                            <th>Điện thoại</th>
                            <th>Email</th>
                            <th>Địa chỉ</th>
                            <th>Ghi chú mặt hàng</th>
                            <th class="text-center" style="width: 140px;">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptSuppliers" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><code><%# Eval("Code") %></code></td>
                                    <td><strong><%# Eval("Name") %></strong></td>
                                    <td><span class="badge badge-secondary">📞 <%# Eval("Phone") %></span></td>
                                    <td><small class="text-muted"><%# Eval("Email") %></small></td>
                                    <td><%# Eval("Address") %></td>
                                    <td><small class="text-muted"><%# Eval("Notes") %></small></td>
                                    <td class="text-center">
                                        <button type="button" class="btn btn-sm btn-outline-primary"
                                                onclick='openEditSupplierModal(<%# Eval("Id") %>, "<%# Eval("Code") %>", "<%# (Eval("Name") ?? "").ToString().Replace("\"", "\\\"").Replace("'", "\\'") %>", "<%# Eval("Phone") %>", "<%# Eval("Email") %>", "<%# (Eval("Address") ?? "").ToString().Replace("\"", "\\\"").Replace("'", "\\'") %>", "<%# (Eval("Notes") ?? "").ToString().Replace("\"", "\\\"").Replace("'", "\\'") %>")'>
                                            ✏️ Sửa
                                        </button>
                                        <asp:LinkButton ID="btnDelete" runat="server" CssClass="btn btn-sm btn-outline-danger"
                                            CommandArgument='<%# Eval("Id") %>' OnClick="btnDelete_Click"
                                            OnClientClick="return confirm('Bạn có chắc muốn xóa nhà cung cấp này?');">
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

    <!-- MODAL NHÀ CUNG CẤP -->
    <div class="modal" id="sup-modal">
        <div class="modal-backdrop" onclick="closeModal('sup-modal')"></div>
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3 id="sup-modal-title">➕ Thêm Nhà Cung Cấp</h3>
                    <button type="button" class="modal-close" onclick="closeModal('sup-modal')">✕</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfSupId" runat="server" Value="0" />
                    <div class="form-group">
                        <label class="form-label">Tên nhà cung cấp / Công ty: <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtSupName" runat="server" CssClass="form-control" placeholder="Ví dụ: Công ty CP Acecook..." required="required" />
                    </div>
                    <div class="form-row">
                        <div class="form-group col-6">
                            <label class="form-label">Điện thoại liên hệ:</label>
                            <asp:TextBox ID="txtSupPhone" runat="server" CssClass="form-control" placeholder="028... hoặc 09..." />
                        </div>
                        <div class="form-group col-6">
                            <label class="form-label">Email:</label>
                            <asp:TextBox ID="txtSupEmail" runat="server" CssClass="form-control" placeholder="lienhe@domain.com" />
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Địa chỉ trụ sở / kho:</label>
                        <asp:TextBox ID="txtSupAddress" runat="server" CssClass="form-control" placeholder="Địa chỉ giao nhận hàng..." />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Ghi chú mặt hàng cung cấp:</label>
                        <asp:TextBox ID="txtSupNotes" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="2" placeholder="Cung cấp mì gói, nước ngọt, dầu ăn..." />
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('sup-modal')">Hủy</button>
                    <asp:Button ID="btnSaveSupplier" runat="server" Text="💾 Lưu Thông Tin" CssClass="btn btn-primary" OnClick="btnSaveSupplier_Click" />
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        function openSupplierModal(mode) {
            document.getElementById('<%= hfSupId.ClientID %>').value = '0';
            document.getElementById('sup-modal-title').textContent = '➕ Thêm Nhà Cung Cấp Mới';
            document.getElementById('<%= txtSupName.ClientID %>').value = '';
            document.getElementById('<%= txtSupPhone.ClientID %>').value = '';
            document.getElementById('<%= txtSupEmail.ClientID %>').value = '';
            document.getElementById('<%= txtSupAddress.ClientID %>').value = '';
            document.getElementById('<%= txtSupNotes.ClientID %>').value = '';
            openModal('sup-modal');
        }

        function openEditSupplierModal(id, code, name, phone, email, address, notes) {
            document.getElementById('<%= hfSupId.ClientID %>').value = id;
            document.getElementById('sup-modal-title').textContent = '✏️ Chỉnh Sửa NCC: ' + name;
            document.getElementById('<%= txtSupName.ClientID %>').value = name;
            document.getElementById('<%= txtSupPhone.ClientID %>').value = phone || '';
            document.getElementById('<%= txtSupEmail.ClientID %>').value = email || '';
            document.getElementById('<%= txtSupAddress.ClientID %>').value = address || '';
            document.getElementById('<%= txtSupNotes.ClientID %>').value = notes || '';
            openModal('sup-modal');
        }
    </script>
</asp:Content>
