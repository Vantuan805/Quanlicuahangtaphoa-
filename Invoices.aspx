<%@ Page Title="Quản Lý Hóa Đơn Bán Hàng" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Invoices.aspx.cs" Inherits="QuanLiCuaHangTapHoa.Invoices" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <!-- TOOLBAR & BỘ LỌC -->
    <div class="card mb-3">
        <div class="card-body p-3">
            <div class="d-flex align-center gap-2 flex-wrap">
                <div class="search-input-group" style="max-width: 280px;">
                    <span class="search-icon">🔍</span>
                    <asp:TextBox ID="txtSearch" runat="server" placeholder="Mã HĐ, tên KH, SĐT..." CssClass="form-control" />
                </div>
                <div class="d-flex align-center gap-1">
                    <label class="form-label mb-0" style="font-size: 0.85rem;">Từ ngày:</label>
                    <asp:TextBox ID="txtFromDate" runat="server" TextMode="Date" CssClass="form-control form-control-sm" />
                </div>
                <div class="d-flex align-center gap-1">
                    <label class="form-label mb-0" style="font-size: 0.85rem;">Đến ngày:</label>
                    <asp:TextBox ID="txtToDate" runat="server" TextMode="Date" CssClass="form-control form-control-sm" />
                </div>
                <asp:Button ID="btnFilter" runat="server" Text="🔍 Lọc Hóa Đơn" CssClass="btn btn-secondary" OnClick="btnFilter_Click" />
                <asp:Button ID="btnReset" runat="server" Text="Làm mới" CssClass="btn btn-outline" OnClick="btnReset_Click" />
            </div>
        </div>
    </div>

    <!-- DANH SÁCH HÓA ĐƠN -->
    <div class="card">
        <div class="card-header d-flex justify-between align-center">
            <h3>🧾 Danh Sách Hóa Đơn Bán Lẻ (<asp:Literal ID="litCount" runat="server" Text="0" />)</h3>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th style="width: 120px;">Mã HĐ</th>
                            <th>Thời gian lập</th>
                            <th>Khách hàng</th>
                            <th>Số điện thoại</th>
                            <th>Thu ngân</th>
                            <th class="text-center">Số món</th>
                            <th class="text-right">Tổng thanh toán</th>
                            <th>Hình thức</th>
                            <th class="text-center" style="width: 140px;">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptInvoices" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><code><%# Eval("Code") %></code></td>
                                    <td><%# string.Format("{0:HH:mm dd/MM/yyyy}", Eval("InvoiceDate")) %></td>
                                    <td><strong><%# Eval("CustomerName") %></strong></td>
                                    <td><small class="text-muted"><%# Eval("CustomerPhone") %></small></td>
                                    <td><%# Eval("EmployeeName") %></td>
                                    <td class="text-center"><span class="badge badge-secondary"><%# Eval("ItemCount") %> món</span></td>
                                    <td class="text-right bold text-success"><%# string.Format("{0:N0} ₫", Eval("TotalAmount")) %></td>
                                    <td>
                                        <span class="badge <%# Eval("PaymentMethod").ToString() == "Tiền mặt" ? "badge-success" : (Eval("PaymentMethod").ToString() == "Chuyển khoản QR" ? "badge-info" : "badge-warning") %>">
                                            <%# Eval("PaymentMethod") %>
                                        </span>
                                    </td>
                                    <td class="text-center">
                                        <button type="button" class="btn btn-sm btn-outline-primary" onclick="viewInvoiceDetails(<%# Eval("Id") %>)">
                                            👁️ Xem & In lại
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

    <!-- MODAL XEM & IN LẠI HÓA ĐƠN -->
    <div class="modal" id="invoice-modal">
        <div class="modal-backdrop" onclick="closeModal('invoice-modal')"></div>
        <div class="modal-dialog modal-receipt">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>🧾 Chi Tiết Hóa Đơn</h3>
                    <button type="button" class="modal-close" onclick="closeModal('invoice-modal')">✕</button>
                </div>
                <div class="modal-body">
                    <div id="invoice-print-area" class="receipt-paper">
                        <div class="receipt-header">
                            <h2 class="receipt-store-name">🏪 TẠP HÓA VIỆT</h2>
                            <p class="receipt-store-address">123 Đường Bách Hóa, Phường 5, Quận 1, TP.HCM</p>
                            <p class="receipt-store-phone">Hotline: 0912.345.678 - 0987.654.321</p>
                            <div class="receipt-title">PHIẾU BÁN LẺ (RE-PRINT)</div>
                            <div class="receipt-meta">
                                <div>Mã HĐ: <strong id="inv-code">HD00000</strong></div>
                                <div>Ngày: <span id="inv-date">01/01/2026 00:00</span></div>
                                <div>Thu ngân: <span id="inv-employee">Trần Thị Mai</span></div>
                                <div>Khách hàng: <span id="inv-customer">Khách lẻ</span></div>
                            </div>
                        </div>

                        <div class="receipt-divider">================================</div>

                        <table class="receipt-table">
                            <thead>
                                <tr>
                                    <th class="th-item">Tên mặt hàng</th>
                                    <th class="th-qty text-center">SL</th>
                                    <th class="th-price text-right">Đ.Giá</th>
                                    <th class="th-total text-right">T.Tiền</th>
                                </tr>
                            </thead>
                            <tbody id="inv-items-tbody">
                            </tbody>
                        </table>

                        <div class="receipt-divider">--------------------------------</div>

                        <div class="receipt-summary">
                            <div class="rec-row">
                                <span>Tiền hàng:</span>
                                <span id="inv-subtotal">0 ₫</span>
                            </div>
                            <div class="rec-row" id="inv-discount-row" style="display:none;">
                                <span>Chiết khấu:</span>
                                <span id="inv-discount">0 ₫</span>
                            </div>
                            <div class="rec-row rec-total-highlight">
                                <span>TỔNG CỘNG:</span>
                                <strong id="inv-total">0 ₫</strong>
                            </div>
                            <div class="rec-row">
                                <span>Hình thức:</span>
                                <span id="inv-payment-method">Tiền mặt</span>
                            </div>
                            <div class="rec-row" id="inv-cash-row">
                                <span>Tiền khách đưa:</span>
                                <span id="inv-cash">0 ₫</span>
                            </div>
                            <div class="rec-row" id="inv-change-row">
                                <span>Tiền thối lại:</span>
                                <strong id="inv-change">0 ₫</strong>
                            </div>
                        </div>

                        <div class="receipt-divider">================================</div>

                        <div class="receipt-footer">
                            <p>Cảm ơn Quý khách & Hẹn gặp lại!</p>
                            <p class="receipt-qr-tip">Kiểm tra hàng trước khi rời quầy</p>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('invoice-modal')">Đóng</button>
                    <button type="button" class="btn btn-primary" onclick="printReceipt('invoice-print-area')">🖨️ In Lại Hóa Đơn</button>
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        function viewInvoiceDetails(id) {
            PageMethods.GetInvoice(id, function (resStr) {
                const res = JSON.parse(resStr);
                if (!res.Success) {
                    showToast(res.Error || 'Không tìm thấy hóa đơn', 'error');
                    return;
                }
                const inv = res.Invoice;
                document.getElementById('inv-code').textContent = inv.Code;
                document.getElementById('inv-date').textContent = new Date(inv.InvoiceDate).toLocaleString('vi-VN');
                document.getElementById('inv-employee').textContent = inv.EmployeeName || 'Thu ngân';
                document.getElementById('inv-customer').textContent = inv.CustomerName || 'Khách vãng lai';

                let tbody = '';
                inv.Items.forEach(it => {
                    tbody += `
                        <tr>
                            <td class="td-item">${it.ProductName}</td>
                            <td class="td-qty text-center">${it.Quantity} ${it.Unit}</td>
                            <td class="td-price text-right">${Number(it.SellingPrice).toLocaleString('vi-VN')} ₫</td>
                            <td class="td-total text-right bold">${Number(it.TotalPrice).toLocaleString('vi-VN')} ₫</td>
                        </tr>
                    `;
                });
                document.getElementById('inv-items-tbody').innerHTML = tbody;

                document.getElementById('inv-subtotal').textContent = Number(inv.Subtotal).toLocaleString('vi-VN') + ' ₫';
                if (inv.Discount > 0) {
                    document.getElementById('inv-discount-row').style.display = 'flex';
                    document.getElementById('inv-discount').textContent = '-' + Number(inv.Discount).toLocaleString('vi-VN') + ' ₫';
                } else {
                    document.getElementById('inv-discount-row').style.display = 'none';
                }
                document.getElementById('inv-total').textContent = Number(inv.TotalAmount).toLocaleString('vi-VN') + ' ₫';
                document.getElementById('inv-payment-method').textContent = inv.PaymentMethod;

                if (inv.PaymentMethod === 'Tiền mặt') {
                    document.getElementById('inv-cash-row').style.display = 'flex';
                    document.getElementById('inv-change-row').style.display = 'flex';
                    document.getElementById('inv-cash').textContent = Number(inv.CustomerPayment).toLocaleString('vi-VN') + ' ₫';
                    document.getElementById('inv-change').textContent = Number(inv.ChangeAmount).toLocaleString('vi-VN') + ' ₫';
                } else {
                    document.getElementById('inv-cash-row').style.display = 'none';
                    document.getElementById('inv-change-row').style.display = 'none';
                }

                openModal('invoice-modal');
            }, function (err) {
                showToast('Lỗi: ' + err.get_message(), 'error');
            });
        }
    </script>
</asp:Content>
