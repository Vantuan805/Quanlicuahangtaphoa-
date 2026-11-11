<%@ Page Title="Báo Cáo & Phân Tích Kinh Doanh" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Reports.aspx.cs" Inherits="QuanLiCuaHangTapHoa.Reports" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .progress-bar-bg {
            background: #e2e8f0;
            border-radius: 9999px;
            height: 8px;
            overflow: hidden;
            margin-top: 4px;
        }
        .progress-bar-fill {
            height: 100%;
            background: var(--primary);
            border-radius: 9999px;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="dashboard-grid-2 mb-4">
        <!-- BÁO CÁO DOANH THU THEO LOẠI SẢN PHẨM -->
        <div class="card">
            <div class="card-header">
                <h3>📊 Doanh Thu & Sản Lượng Theo Loại Hàng</h3>
                <span class="badge badge-info">Toàn thời gian</span>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Loại sản phẩm</th>
                                <th class="text-center">Đã bán</th>
                                <th class="text-right">Doanh thu</th>
                                <th style="width: 120px;">Tỷ trọng</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rptCategorySales" runat="server">
                                <ItemTemplate>
                                    <tr>
                                        <td><%# Container.ItemIndex + 1 %></td>
                                        <td><strong><%# Eval("Name") %></strong></td>
                                        <td class="text-center"><%# Eval("UnitsSold") %></td>
                                        <td class="text-right bold"><%# string.Format("{0:N0} ₫", Eval("Revenue")) %></td>
                                        <td>
                                            <div class="d-flex justify-between" style="font-size:0.8rem;">
                                                <span><%# GetPercent(Eval("Revenue")) %>%</span>
                                            </div>
                                            <div class="progress-bar-bg">
                                                <div class="progress-bar-fill" style="width: <%# GetPercent(Eval("Revenue")) %>%;"></div>
                                            </div>
                                        </td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- CƠ CẤU PHƯƠNG THỨC THANH TOÁN -->
        <div class="card">
            <div class="card-header">
                <h3>💳 Cơ Cấu Phương Thức Thanh Toán</h3>
                <span class="badge badge-success">Giao dịch thực tế</span>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Phương thức</th>
                                <th class="text-center">Số giao dịch</th>
                                <th class="text-right">Tổng thanh toán</th>
                                <th style="width: 120px;">Tỷ trọng</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rptPaymentMethods" runat="server">
                                <ItemTemplate>
                                    <tr>
                                        <td>
                                            <span class="badge <%# Eval("PaymentMethod").ToString() == "Tiền mặt" ? "badge-success" : (Eval("PaymentMethod").ToString() == "Chuyển khoản QR" ? "badge-info" : "badge-warning") %>">
                                                <%# Eval("PaymentMethod") %>
                                            </span>
                                        </td>
                                        <td class="text-center bold"><%# Eval("Count") %> đơn</td>
                                        <td class="text-right bold text-primary"><%# string.Format("{0:N0} ₫", Eval("Total")) %></td>
                                        <td>
                                            <div class="d-flex justify-between" style="font-size:0.8rem;">
                                                <span><%# GetPaymentPercent(Eval("Total")) %>%</span>
                                            </div>
                                            <div class="progress-bar-bg">
                                                <div class="progress-bar-fill" style="width: <%# GetPaymentPercent(Eval("Total")) %>%;"></div>
                                            </div>
                                        </td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- TOP 10 SẢN PHẨM DOANH THU & LỢI NHUẬN CAO NHẤT -->
    <div class="card">
        <div class="card-header d-flex justify-between align-center">
            <h3>🔥 Top 10 Sản Phẩm Doanh Thu & Lợi Nhuận Gộp Cao Nhất</h3>
            <span class="badge badge-primary">Xếp hạng lợi nhuận</span>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th class="text-center" style="width: 40px;">#</th>
                            <th style="width: 50px;">Icon</th>
                            <th>Mã SP</th>
                            <th>Tên mặt hàng</th>
                            <th>ĐVT</th>
                            <th class="text-center">Số lượng bán</th>
                            <th class="text-right">Tổng doanh thu</th>
                            <th class="text-right">Lợi nhuận gộp</th>
                            <th class="text-center">Tỷ suất lãi</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptTopProducts" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td class="text-center bold"><%# Container.ItemIndex + 1 %></td>
                                    <td class="text-center" style="font-size: 20px;"><%# Eval("ImageIcon") %></td>
                                    <td><code><%# Eval("Code") %></code></td>
                                    <td><strong><%# Eval("Name") %></strong></td>
                                    <td><%# Eval("Unit") %></td>
                                    <td class="text-center bold"><%# Eval("TotalSold") %></td>
                                    <td class="text-right bold"><%# string.Format("{0:N0} ₫", Eval("TotalRevenue")) %></td>
                                    <td class="text-right bold text-success"><%# string.Format("{0:N0} ₫", Eval("TotalProfit")) %></td>
                                    <td class="text-center">
                                        <span class="badge badge-success">
                                            <%# GetMarginPercent(Eval("TotalProfit"), Eval("TotalRevenue")) %>%
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
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>
