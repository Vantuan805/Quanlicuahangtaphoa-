<%@ Page Title="Quản Lý Nhân Viên" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Employees.aspx.cs" Inherits="QuanLiCuaHangTapHoa.Employees" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="card">
        <div class="card-header d-flex justify-between align-center">
            <h3>🧑‍💼 Danh Sách Nhân Viên Cửa Hàng (<asp:Literal ID="litCount" runat="server" Text="0" />)</h3>
            <button type="button" class="btn btn-primary" onclick="openEmployeeModal('add')">
                ➕ Thêm nhân viên mới
            </button>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th style="width: 80px;">Mã NV</th>
                            <th>Họ và tên</th>
                            <th>Số điện thoại</th>
                            <th>Vị trí / Vai trò</th>
                            <th>Trạng thái</th>
                            <th>Ngày bắt đầu</th>
                            <th class="text-center" style="width: 140px;">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptEmployees" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><code><%# Eval("Code") %></code></td>
                                    <td><strong><%# Eval("Name") %></strong></td>
                                    <td><span class="badge badge-secondary">📞 <%# Eval("Phone") %></span></td>
                                    <td>
                                        <span class="badge <%# Eval("Role").ToString() == "Quản lý" ? "badge-primary" : (Eval("Role").ToString() == "Thu ngân" ? "badge-success" : "badge-info") %>">
                                            <%# Eval("Role") %>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge <%# Eval("Status").ToString() == "active" ? "badge-success" : "badge-danger" %>">
                                            <%# Eval("Status").ToString() == "active" ? "Đang làm việc" : "Đã nghỉ" %>
                                        </span>
                                    </td>
                                    <td><%# string.Format("{0:dd/MM/yyyy}", Eval("CreatedAt")) %></td>
                                    <td class="text-center">
                                        <button type="button" class="btn btn-sm btn-outline-primary"
                                                onclick='openEditEmployeeModal(<%# Eval("Id") %>, "<%# Eval("Code") %>", "<%# Eval("Name") %>", "<%# Eval("Phone") %>", "<%# Eval("Role") %>", "<%# Eval("Status") %>")'>
                                            ✏️ Sửa
                                        </button>
                                        <asp:LinkButton ID="btnDelete" runat="server" CssClass="btn btn-sm btn-outline-danger"
                                            CommandArgument='<%# Eval("Id") %>' OnClick="btnDelete_Click"
                                            OnClientClick="return confirm('Bạn có chắc muốn xóa nhân viên này?');">
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

    <!-- MODAL NHÂN VIÊN -->
    <div class="modal" id="emp-modal">
        <div class="modal-backdrop" onclick="closeModal('emp-modal')"></div>
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3 id="emp-modal-title">➕ Thêm Nhân Viên Mới</h3>
                    <button type="button" class="modal-close" onclick="closeModal('emp-modal')">✕</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfEmpId" runat="server" Value="0" />
                    <div class="form-group">
                        <label class="form-label">Họ và tên nhân viên: <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtEmpName" runat="server" CssClass="form-control" placeholder="Ví dụ: Nguyễn Văn Quản..." required="required" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Số điện thoại liên hệ:</label>
                        <asp:TextBox ID="txtEmpPhone" runat="server" CssClass="form-control" placeholder="09..." />
                    </div>
                    <div class="form-row">
                        <div class="form-group col-6">
                            <label class="form-label">Vai trò / Chức vụ:</label>
                            <asp:DropDownList ID="ddlEmpRole" runat="server" CssClass="form-control">
                                <asp:ListItem Text="Thu ngân" Value="Thu ngân" Selected="True" />
                                <asp:ListItem Text="Quản lý" Value="Quản lý" />
                                <asp:ListItem Text="Nhân viên kho" Value="Nhân viên kho" />
                            </asp:DropDownList>
                        </div>
                        <div class="form-group col-6">
                            <label class="form-label">Trạng thái:</label>
                            <asp:DropDownList ID="ddlEmpStatus" runat="server" CssClass="form-control">
                                <asp:ListItem Text="Đang làm việc" Value="active" Selected="True" />
                                <asp:ListItem Text="Tạm nghỉ / Đã nghỉ" Value="inactive" />
                            </asp:DropDownList>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('emp-modal')">Hủy</button>
                    <asp:Button ID="btnSaveEmployee" runat="server" Text="💾 Lưu Thông Tin" CssClass="btn btn-primary" OnClick="btnSaveEmployee_Click" />
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        function openEmployeeModal(mode) {
            document.getElementById('<%= hfEmpId.ClientID %>').value = '0';
            document.getElementById('emp-modal-title').textContent = '➕ Thêm Nhân Viên Mới';
            document.getElementById('<%= txtEmpName.ClientID %>').value = '';
            document.getElementById('<%= txtEmpPhone.ClientID %>').value = '';
            document.getElementById('<%= ddlEmpRole.ClientID %>').value = 'Thu ngân';
            document.getElementById('<%= ddlEmpStatus.ClientID %>').value = 'active';
            openModal('emp-modal');
        }

        function openEditEmployeeModal(id, code, name, phone, role, status) {
            document.getElementById('<%= hfEmpId.ClientID %>').value = id;
            document.getElementById('emp-modal-title').textContent = '✏️ Chỉnh Sửa Nhân Viên: ' + name;
            document.getElementById('<%= txtEmpName.ClientID %>').value = name;
            document.getElementById('<%= txtEmpPhone.ClientID %>').value = phone || '';
            document.getElementById('<%= ddlEmpRole.ClientID %>').value = role || 'Thu ngân';
            document.getElementById('<%= ddlEmpStatus.ClientID %>').value = status || 'active';
            openModal('emp-modal');
        }
    </script>
</asp:Content>
