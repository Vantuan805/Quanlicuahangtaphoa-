<%@ Page Title="Quản Lý Loại Sản Phẩm" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Categories.aspx.cs" Inherits="QuanLiCuaHangTapHoa.Categories" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="card">
        <div class="card-header d-flex justify-between align-center">
            <h3>🏷️ Danh Sách Loại Sản Phẩm (<asp:Literal ID="litCount" runat="server" Text="0" />)</h3>
            <button type="button" class="btn btn-primary" onclick="openCategoryModal('add')">
                ➕ Thêm loại mới
            </button>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th style="width: 80px;">Mã</th>
                            <th>Tên loại sản phẩm</th>
                            <th>Mô tả chi tiết</th>
                            <th class="text-center">Số sản phẩm</th>
                            <th>Ngày tạo</th>
                            <th class="text-center" style="width: 140px;">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptCategories" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><code><%# Eval("Code") %></code></td>
                                    <td><strong><%# Eval("Name") %></strong></td>
                                    <td><span class="text-muted"><%# Eval("Description") %></span></td>
                                    <td class="text-center">
                                        <span class="badge badge-info"><%# Eval("ProductCount") %> mặt hàng</span>
                                    </td>
                                    <td><%# string.Format("{0:dd/MM/yyyy}", Eval("CreatedAt")) %></td>
                                    <td class="text-center">
                                        <button type="button" class="btn btn-sm btn-outline-primary"
                                                onclick='openEditCategoryModal(<%# Eval("Id") %>, "<%# Eval("Code") %>", "<%# Eval("Name") %>", "<%# Eval("Description") %>")'>
                                            ✏️ Sửa
                                        </button>
                                        <asp:LinkButton ID="btnDelete" runat="server" CssClass="btn btn-sm btn-outline-danger"
                                            CommandArgument='<%# Eval("Id") %>' OnClick="btnDelete_Click"
                                            OnClientClick="return confirm('Bạn có chắc muốn xóa loại sản phẩm này?');">
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

    <!-- MODAL LOẠI SẢN PHẨM -->
    <div class="modal" id="cat-modal">
        <div class="modal-backdrop" onclick="closeModal('cat-modal')"></div>
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3 id="cat-modal-title">➕ Thêm Loại Sản Phẩm</h3>
                    <button type="button" class="modal-close" onclick="closeModal('cat-modal')">✕</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfCatId" runat="server" Value="0" />
                    <div class="form-group">
                        <label class="form-label">Tên loại sản phẩm: <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtCatName" runat="server" CssClass="form-control" placeholder="Ví dụ: Đồ uống, Bánh kẹo..." required="required" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Mô tả:</label>
                        <asp:TextBox ID="txtCatDesc" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" placeholder="Ghi chú chi tiết về nhóm hàng..." />
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('cat-modal')">Hủy</button>
                    <asp:Button ID="btnSaveCategory" runat="server" Text="💾 Lưu Thông Tin" CssClass="btn btn-primary" OnClick="btnSaveCategory_Click" />
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        function openCategoryModal(mode) {
            document.getElementById('<%= hfCatId.ClientID %>').value = '0';
            document.getElementById('cat-modal-title').textContent = '➕ Thêm Loại Sản Phẩm Mới';
            document.getElementById('<%= txtCatName.ClientID %>').value = '';
            document.getElementById('<%= txtCatDesc.ClientID %>').value = '';
            openModal('cat-modal');
        }

        function openEditCategoryModal(id, code, name, desc) {
            document.getElementById('<%= hfCatId.ClientID %>').value = id;
            document.getElementById('cat-modal-title').textContent = '✏️ Chỉnh Sửa Loại: ' + name;
            document.getElementById('<%= txtCatName.ClientID %>').value = name;
            document.getElementById('<%= txtCatDesc.ClientID %>').value = desc || '';
            openModal('cat-modal');
        }
    </script>
</asp:Content>
