<%@ Page Title="Quản Lý Phiếu Nhập Hàng" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="GoodsReceipts.aspx.cs" Inherits="QuanLiCuaHangTapHoa.GoodsReceipts" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .receipt-line-item {
            background: #f8fafc;
            padding: 10px;
            border-radius: var(--radius-sm);
            margin-bottom: 8px;
            border: 1px solid var(--border-color);
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="card">
        <div class="card-header d-flex justify-between align-center">
            <h3>📥 Danh Sách Phiếu Nhập Hàng (<asp:Literal ID="litCount" runat="server" Text="0" />)</h3>
            <button type="button" class="btn btn-primary" onclick="openCreateReceiptModal()">
                ➕ Lập phiếu nhập hàng mới
            </button>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th style="width: 110px;">Mã phiếu</th>
                            <th>Nhà cung cấp</th>
                            <th>Người lập</th>
                            <th>Thời gian nhập</th>
                            <th class="text-center">Số món</th>
                            <th class="text-right">Tổng tiền hàng</th>
                            <th>Ghi chú</th>
                            <th class="text-center" style="width: 100px;">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptReceipts" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><code><%# Eval("Code") %></code></td>
                                    <td><strong><%# Eval("SupplierName") %></strong></td>
                                    <td><%# Eval("EmployeeName") %></td>
                                    <td><%# string.Format("{0:HH:mm dd/MM/yyyy}", Eval("ReceiptDate")) %></td>
                                    <td class="text-center"><span class="badge badge-secondary"><%# Eval("ItemCount") %> mặt hàng</span></td>
                                    <td class="text-right bold text-primary"><%# string.Format("{0:N0} ₫", Eval("TotalAmount")) %></td>
                                    <td><small class="text-muted"><%# Eval("Notes") %></small></td>
                                    <td class="text-center">
                                        <button type="button" class="btn btn-sm btn-outline-primary" onclick="viewReceiptDetails(<%# Eval("Id") %>)">
                                            👁️ Chi tiết
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

    <!-- MODAL LẬP PHIẾU NHẬP MỚI -->
    <div class="modal" id="create-receipt-modal">
        <div class="modal-backdrop" onclick="closeModal('create-receipt-modal')"></div>
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>📥 Lập Phiếu Nhập Hàng Từ Nhà Cung Cấp</h3>
                    <button type="button" class="modal-close" onclick="closeModal('create-receipt-modal')">✕</button>
                </div>
                <div class="modal-body">
                    <div class="form-row">
                        <div class="form-group col-6">
                            <label class="form-label">Chọn nhà cung cấp: <span class="text-danger">*</span></label>
                            <select id="receipt-supplier-select" class="form-control">
                                <option value="">--- Chọn nhà phân phối / NCC ---</option>
                                <asp:Repeater ID="rptModalSuppliers" runat="server">
                                    <ItemTemplate>
                                        <option value="<%# Eval("Id") %>"><%# Eval("Name") %></option>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </select>
                        </div>
                        <div class="form-group col-6">
                            <label class="form-label">Nhân viên tiếp nhận kho:</label>
                            <select id="receipt-employee-select" class="form-control">
                                <asp:Repeater ID="rptModalEmployees" runat="server">
                                    <ItemTemplate>
                                        <option value="<%# Eval("Id") %>"><%# Eval("Name") %> (<%# Eval("Role") %>)</option>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </select>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Ghi chú phiếu nhập:</label>
                        <input type="text" id="receipt-notes" class="form-control" placeholder="Ví dụ: Nhập định kỳ đầu tuần..." />
                    </div>

                    <hr class="my-3" />

                    <div class="d-flex justify-between align-center mb-2">
                        <h4>📦 Danh sách sản phẩm nhập kho</h4>
                        <button type="button" class="btn btn-sm btn-secondary" onclick="addReceiptRow()">➕ Thêm dòng</button>
                    </div>

                    <div id="receipt-items-rows">
                        <!-- Dynamic input rows -->
                    </div>

                    <div class="d-flex justify-end align-center mt-3 p-3" style="background: #f1f5f9; border-radius: var(--radius-sm);">
                        <span class="mr-3" style="margin-right: 15px;">Tổng giá trị phiếu nhập:</span>
                        <strong class="text-primary bold" style="font-size: 1.3rem;" id="receipt-total-display">0 ₫</strong>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('create-receipt-modal')">Hủy</button>
                    <button type="button" class="btn btn-primary" id="btn-submit-receipt" onclick="submitReceipt()">💾 Xác Nhận Nhập Kho</button>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL XEM CHI TIẾT PHIẾU NHẬP -->
    <div class="modal" id="view-receipt-modal">
        <div class="modal-backdrop" onclick="closeModal('view-receipt-modal')"></div>
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>Chi Tiết Phiếu Nhập: <span id="vrec-code">PN...</span></h3>
                    <button type="button" class="modal-close" onclick="closeModal('view-receipt-modal')">✕</button>
                </div>
                <div class="modal-body">
                    <div class="d-flex justify-between flex-wrap gap-2 mb-3 p-3" style="background:#f8fafc; border-radius:var(--radius-sm);">
                        <div>
                            <div>Nhà cung cấp: <strong id="vrec-supplier"></strong></div>
                            <div>Điện thoại: <span id="vrec-phone"></span></div>
                            <div>Địa chỉ: <span id="vrec-address"></span></div>
                        </div>
                        <div>
                            <div>Ngày lập: <strong id="vrec-date"></strong></div>
                            <div>Người lập: <span id="vrec-employee"></span></div>
                            <div>Ghi chú: <span id="vrec-notes"></span></div>
                        </div>
                    </div>

                    <table class="table table-bordered">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Mã SP</th>
                                <th>Tên sản phẩm</th>
                                <th>ĐVT</th>
                                <th class="text-center">Số lượng</th>
                                <th class="text-right">Đơn giá nhập</th>
                                <th class="text-right">Thành tiền</th>
                            </tr>
                        </thead>
                        <tbody id="vrec-items-tbody">
                        </tbody>
                        <tfoot>
                            <tr>
                                <th colspan="6" class="text-right">TỔNG CỘNG:</th>
                                <th class="text-right text-primary bold" id="vrec-total">0 ₫</th>
                            </tr>
                        </tfoot>
                    </table>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('view-receipt-modal')">Đóng</button>
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        var availableProducts = <%= ProductsJson %>;

        function openCreateReceiptModal() {
            document.getElementById('receipt-supplier-select').value = '';
            document.getElementById('receipt-notes').value = '';
            document.getElementById('receipt-items-rows').innerHTML = '';
            addReceiptRow();
            addReceiptRow();
            calculateReceiptTotal();
            openModal('create-receipt-modal');
        }

        function addReceiptRow() {
            const container = document.getElementById('receipt-items-rows');
            const rowId = 'row_' + Date.now() + '_' + Math.floor(Math.random() * 1000);

            let options = '<option value="">-- Chọn sản phẩm --</option>';
            availableProducts.forEach(p => {
                options += `<option value="${p.Id}" data-cost="${p.CostPrice}" data-unit="${p.Unit}">${p.Name} (${p.Unit})</option>`;
            });

            const rowDiv = document.createElement('div');
            rowDiv.className = 'receipt-line-item d-flex align-center gap-2 flex-wrap';
            rowDiv.id = rowId;
            rowDiv.innerHTML = `
                <div style="flex: 3; min-width: 200px;">
                    <select class="form-control form-control-sm rec-prod-select" onchange="onReceiptProductSelect('${rowId}', this)">
                        ${options}
                    </select>
                </div>
                <div style="flex: 1; min-width: 90px;">
                    <input type="number" class="form-control form-control-sm rec-qty-input" placeholder="SL" value="10" min="1" oninput="calculateReceiptTotal()" />
                </div>
                <div style="flex: 1.5; min-width: 120px;">
                    <input type="number" class="form-control form-control-sm rec-cost-input" placeholder="Đơn giá nhập" value="0" min="0" step="500" oninput="calculateReceiptTotal()" />
                </div>
                <div style="flex: 1.5; min-width: 120px; text-align: right;">
                    <strong class="rec-line-total text-success">0 ₫</strong>
                </div>
                <div style="width: 40px; text-align: center;">
                    <button type="button" class="btn btn-sm btn-outline-danger" onclick="removeReceiptRow('${rowId}')">✕</button>
                </div>
            `;
            container.appendChild(rowDiv);
            calculateReceiptTotal();
        }

        function removeReceiptRow(rowId) {
            const row = document.getElementById(rowId);
            if (row) row.parentElement.removeChild(row);
            calculateReceiptTotal();
        }

        function onReceiptProductSelect(rowId, selectEl) {
            const row = document.getElementById(rowId);
            if (!row) return;
            const opt = selectEl.options[selectEl.selectedIndex];
            if (opt && opt.value) {
                const cost = opt.dataset.cost || '0';
                row.querySelector('.rec-cost-input').value = cost;
            }
            calculateReceiptTotal();
        }

        function calculateReceiptTotal() {
            const rows = document.querySelectorAll('#receipt-items-rows .receipt-line-item');
            let total = 0;
            rows.forEach(r => {
                const qty = parseInt(r.querySelector('.rec-qty-input').value) || 0;
                const cost = parseFloat(r.querySelector('.rec-cost-input').value) || 0;
                const lineTotal = qty * cost;
                r.querySelector('.rec-line-total').textContent = lineTotal.toLocaleString('vi-VN') + ' ₫';
                total += lineTotal;
            });
            document.getElementById('receipt-total-display').textContent = total.toLocaleString('vi-VN') + ' ₫';
        }

        function submitReceipt() {
            const supVal = document.getElementById('receipt-supplier-select').value;
            if (!supVal) {
                showToast('Vui lòng chọn Nhà cung cấp!', 'warning');
                return;
            }

            const empVal = document.getElementById('receipt-employee-select').value;
            const notes = document.getElementById('receipt-notes').value.trim();

            const rows = document.querySelectorAll('#receipt-items-rows .receipt-line-item');
            const items = [];
            rows.forEach(r => {
                const prodId = r.querySelector('.rec-prod-select').value;
                const qty = parseInt(r.querySelector('.rec-qty-input').value) || 0;
                const cost = parseFloat(r.querySelector('.rec-cost-input').value) || 0;
                if (prodId && qty > 0) {
                    items.push({
                        ProductId: parseInt(prodId),
                        Quantity: qty,
                        CostPrice: cost
                    });
                }
            });

            if (items.length === 0) {
                showToast('Vui lòng chọn ít nhất 1 sản phẩm hợp lệ!', 'warning');
                return;
            }

            const payload = {
                SupplierId: parseInt(supVal),
                EmployeeId: empVal ? parseInt(empVal) : 0,
                Notes: notes,
                Items: items
            };

            document.getElementById('btn-submit-receipt').disabled = true;
            document.getElementById('btn-submit-receipt').textContent = 'Đang xử lý...';

            PageMethods.CreateReceipt(JSON.stringify(payload), function (resStr) {
                document.getElementById('btn-submit-receipt').disabled = false;
                document.getElementById('btn-submit-receipt').textContent = '💾 Xác Nhận Nhập Kho';

                const res = JSON.parse(resStr);
                if (res.Success) {
                    showToast('Đã nhập kho thành công! Số lượng tồn kho đã được cập nhật.', 'success');
                    closeModal('create-receipt-modal');
                    setTimeout(() => window.location.reload(), 1000);
                } else {
                    showToast(res.Error || 'Lỗi khi nhập kho!', 'error');
                }
            }, function (err) {
                document.getElementById('btn-submit-receipt').disabled = false;
                document.getElementById('btn-submit-receipt').textContent = '💾 Xác Nhận Nhập Kho';
                showToast('Lỗi máy chủ: ' + err.get_message(), 'error');
            });
        }

        function viewReceiptDetails(id) {
            PageMethods.GetReceiptDetails(id, function (resStr) {
                const res = JSON.parse(resStr);
                if (!res.Success) {
                    showToast(res.Error || 'Không tìm thấy phiếu nhập', 'error');
                    return;
                }
                const rec = res.Receipt;
                document.getElementById('vrec-code').textContent = rec.Code;
                document.getElementById('vrec-supplier').textContent = rec.SupplierName || 'Chưa xác định';
                document.getElementById('vrec-phone').textContent = rec.SupplierPhone || 'N/A';
                document.getElementById('vrec-address').textContent = rec.SupplierAddress || 'N/A';
                document.getElementById('vrec-date').textContent = new Date(rec.ReceiptDate).toLocaleString('vi-VN');
                document.getElementById('vrec-employee').textContent = rec.EmployeeName || 'N/A';
                document.getElementById('vrec-notes').textContent = rec.Notes || 'Không có';

                let tbody = '';
                rec.Items.forEach((it, idx) => {
                    tbody += `
                        <tr>
                            <td>${idx + 1}</td>
                            <td><code>${it.ProductCode}</code></td>
                            <td><strong>${it.ProductName}</strong></td>
                            <td>${it.Unit}</td>
                            <td class="text-center bold">${it.Quantity}</td>
                            <td class="text-right">${Number(it.CostPrice).toLocaleString('vi-VN')} ₫</td>
                            <td class="text-right bold text-success">${Number(it.TotalPrice).toLocaleString('vi-VN')} ₫</td>
                        </tr>
                    `;
                });
                document.getElementById('vrec-items-tbody').innerHTML = tbody;
                document.getElementById('vrec-total').textContent = Number(rec.TotalAmount).toLocaleString('vi-VN') + ' ₫';

                openModal('view-receipt-modal');
            }, function (err) {
                showToast('Lỗi: ' + err.get_message(), 'error');
            });
        }
    </script>
</asp:Content>
