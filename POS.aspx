<%@ Page Title="Quầy Thu Ngân (POS Bán Hàng)" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="POS.aspx.cs" Inherits="QuanLiCuaHangTapHoa.POS" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .pos-product-card {
            cursor: pointer;
            transition: transform 0.15s ease, box-shadow 0.15s ease;
        }
        .pos-product-card:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-md);
        }
        .pos-product-card.out-of-stock {
            opacity: 0.55;
            cursor: not-allowed;
            filter: grayscale(0.6);
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pos-layout">
        <!-- Bên trái: Danh mục & Lưới hàng hóa -->
        <div class="pos-catalog">
            <!-- Thanh tìm kiếm & quét Barcode -->
            <div class="pos-search-bar">
                <div class="search-input-group">
                    <span class="search-icon">🔍</span>
                    <input type="text" id="pos-search-input" placeholder="Tìm theo tên sản phẩm hoặc quét mã vạch (Barcode)..." autocomplete="off" />
                    <button type="button" id="pos-search-clear" class="btn-clear" style="display:none;" onclick="clearSearch()">✕</button>
                </div>
            </div>

            <!-- Chips phân loại nhanh -->
            <div class="pos-category-chips" id="pos-category-chips">
                <button type="button" class="chip active" onclick="filterCategory(0, this)">Tất cả</button>
                <asp:Repeater ID="rptCategories" runat="server">
                    <ItemTemplate>
                        <button type="button" class="chip" onclick="filterCategory(<%# Eval("Id") %>, this)"><%# Eval("Name") %></button>
                    </ItemTemplate>
                </asp:Repeater>
            </div>

            <!-- Lưới sản phẩm -->
            <div class="pos-product-grid" id="pos-product-grid">
                <asp:Repeater ID="rptProducts" runat="server">
                    <ItemTemplate>
                        <div class="pos-product-card <%# (int)Eval("StockQuantity") <= 0 ? "out-of-stock" : "" %>"
                             data-id="<%# Eval("Id") %>"
                             data-code="<%# Eval("Code") %>"
                             data-barcode="<%# Eval("Barcode") %>"
                             data-name="<%# Eval("Name") %>"
                             data-price="<%# Eval("SellingPrice") %>"
                             data-stock="<%# Eval("StockQuantity") %>"
                             data-unit="<%# Eval("Unit") %>"
                             data-cat-id="<%# Eval("CategoryId") ?? 0 %>"
                             onclick="addToCartFromElement(this)">
                            <div class="product-icon"><%# Eval("ImageIcon") %></div>
                            <div class="product-meta">
                                <span class="product-code"><%# Eval("Code") %></span>
                                <h4 class="product-name" title="<%# Eval("Name") %>"><%# Eval("Name") %></h4>
                                <div class="product-bottom">
                                    <span class="product-price"><%# string.Format("{0:N0} ₫", Eval("SellingPrice")) %></span>
                                    <span class="product-stock <%# (int)Eval("StockQuantity") <= 5 ? "low" : "" %>">
                                        Tồn: <%# Eval("StockQuantity") %>
                                    </span>
                                </div>
                            </div>
                        </div>
                    </ItemTemplate>
                </asp:Repeater>
            </div>
        </div>

        <!-- Bên phải: Giỏ hàng & Thanh toán -->
        <div class="pos-cart-panel">
            <div class="cart-header">
                <h3>🛒 Giỏ hàng (<span id="cart-item-count">0</span> món)</h3>
                <button type="button" class="btn btn-sm btn-outline-danger" onclick="clearCart()" title="Xóa toàn bộ giỏ hàng">Xóa giỏ</button>
            </div>

            <!-- Chọn khách hàng & nhân viên -->
            <div class="cart-customer-bar">
                <div class="form-group mb-1">
                    <label class="cart-label">Khách hàng:</label>
                    <select id="pos-customer-select" class="form-control form-control-sm" onchange="onCustomerChange()">
                        <option value="">Khách vãng lai (Lẻ)</option>
                        <asp:Repeater ID="rptCustomers" runat="server">
                            <ItemTemplate>
                                <option value="<%# Eval("Id") %>" data-points="<%# Eval("Points") %>" data-spent="<%# Eval("TotalSpent") %>">
                                    <%# Eval("Name") %> - <%# Eval("Phone") %>
                                </option>
                            </ItemTemplate>
                        </asp:Repeater>
                    </select>
                    <div id="pos-customer-info" class="customer-info-pill" style="display:none; margin-top: 4px;">
                        <span>Điểm: <b id="pos-cust-points">0</b></span> | 
                        <span>Đã mua: <b id="pos-cust-spent">0 ₫</b></span>
                    </div>
                </div>

                <div class="form-group mb-0">
                    <label class="cart-label">Nhân viên thu ngân:</label>
                    <select id="pos-employee-select" class="form-control form-control-sm">
                        <asp:Repeater ID="rptEmployees" runat="server">
                            <ItemTemplate>
                                <option value="<%# Eval("Id") %>"><%# Eval("Name") %> (<%# Eval("Role") %>)</option>
                            </ItemTemplate>
                        </asp:Repeater>
                    </select>
                </div>
            </div>

            <!-- Danh sách items trong giỏ -->
            <div class="cart-items-container" id="cart-items-list">
                <div class="empty-cart-message" id="empty-cart-msg">
                    <div class="empty-cart-icon">🛒</div>
                    <p>Giỏ hàng đang trống</p>
                    <small class="text-muted">Nhấp vào sản phẩm bên trái hoặc gõ tên/barcode để thêm vào giỏ.</small>
                </div>
            </div>

            <!-- Tổng kết thanh toán -->
            <div class="cart-summary">
                <div class="summary-row">
                    <span>Tiền hàng:</span>
                    <strong id="cart-subtotal">0 ₫</strong>
                </div>
                <div class="summary-row">
                    <span>Giảm giá / Chiết khấu:</span>
                    <div class="discount-input-wrap">
                        <input type="number" id="cart-discount-input" value="0" min="0" step="1000" class="input-discount" oninput="calculateTotals()" />
                        <span>₫</span>
                    </div>
                </div>
                <div class="summary-row total-highlight">
                    <span>KHÁCH CẦN TRẢ:</span>
                    <span class="total-big" id="cart-total-amount">0 ₫</span>
                </div>
                <div class="summary-row">
                    <span>Hình thức thanh toán:</span>
                    <select id="cart-payment-method" class="form-control form-control-sm select-payment" onchange="onPaymentMethodChange()">
                        <option value="Tiền mặt">💵 Tiền mặt</option>
                        <option value="Chuyển khoản QR">📱 Chuyển khoản QR</option>
                        <option value="Thẻ">💳 Thẻ ngân hàng</option>
                    </select>
                </div>
                <div class="summary-row" id="row-customer-payment">
                    <span>Tiền khách đưa:</span>
                    <div class="payment-input-wrap">
                        <input type="number" id="cart-customer-payment" placeholder="Nhập số tiền..." min="0" step="1000" class="input-payment" oninput="calculateChange()" />
                        <span>₫</span>
                    </div>
                </div>
                <div class="quick-cash-buttons" id="quick-cash-pills">
                    <button type="button" class="btn-cash" onclick="setQuickCash('exact')">Đúng số tiền</button>
                    <button type="button" class="btn-cash" onclick="setQuickCash(50000)">50k</button>
                    <button type="button" class="btn-cash" onclick="setQuickCash(100000)">100k</button>
                    <button type="button" class="btn-cash" onclick="setQuickCash(200000)">200k</button>
                    <button type="button" class="btn-cash" onclick="setQuickCash(500000)">500k</button>
                </div>
                <div class="summary-row change-row" id="row-change-amount">
                    <span>Tiền thối lại:</span>
                    <strong class="text-success" id="cart-change-amount">0 ₫</strong>
                </div>

                <div class="cart-actions">
                    <button type="button" class="btn btn-primary btn-checkout" id="btn-checkout" onclick="performCheckout()">
                        ⚡ THANH TOÁN & IN HÓA ĐƠN
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL IN HÓA ĐƠN -->
    <div class="modal" id="receipt-modal">
        <div class="modal-backdrop" onclick="closeModal('receipt-modal')"></div>
        <div class="modal-dialog modal-receipt">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>🧾 Hóa Đơn Bán Hàng</h3>
                    <button type="button" class="modal-close" onclick="closeModal('receipt-modal')">✕</button>
                </div>
                <div class="modal-body">
                    <div id="receipt-print-area" class="receipt-paper">
                        <div class="receipt-header">
                            <h2 class="receipt-store-name">🏪 TẠP HÓA VIỆT</h2>
                            <p class="receipt-store-address">123 Đường Bách Hóa, Phường 5, Quận 1, TP.HCM</p>
                            <p class="receipt-store-phone">Hotline: 0912.345.678 - 0987.654.321</p>
                            <div class="receipt-title">PHIẾU THANH TOÁN</div>
                            <div class="receipt-meta">
                                <div>Mã HĐ: <strong id="rec-code">HD00000</strong></div>
                                <div>Ngày: <span id="rec-date">01/01/2026 00:00</span></div>
                                <div>Thu ngân: <span id="rec-employee">Trần Thị Mai</span></div>
                                <div>Khách hàng: <span id="rec-customer">Khách lẻ</span></div>
                            </div>
                        </div>

                        <div class="receipt-divider">================================</div>

                        <table class="receipt-table">
                            <thead>
                                <tr>
                                    <th class="th-item">Tên mặt hàng</th>
                                    <th class="th-qty">SL</th>
                                    <th class="th-price">Đ.Giá</th>
                                    <th class="th-total">T.Tiền</th>
                                </tr>
                            </thead>
                            <tbody id="rec-items-tbody">
                                <!-- Dynamic lines -->
                            </tbody>
                        </table>

                        <div class="receipt-divider">--------------------------------</div>

                        <div class="receipt-summary">
                            <div class="rec-row">
                                <span>Tổng tiền hàng:</span>
                                <span id="rec-subtotal">0 ₫</span>
                            </div>
                            <div class="rec-row" id="rec-discount-row" style="display:none;">
                                <span>Chiết khấu / Giảm giá:</span>
                                <span id="rec-discount">0 ₫</span>
                            </div>
                            <div class="rec-row rec-total-highlight">
                                <span>THANH TOÁN:</span>
                                <strong id="rec-total">0 ₫</strong>
                            </div>
                            <div class="rec-row">
                                <span>Hình thức:</span>
                                <span id="rec-payment-method">Tiền mặt</span>
                            </div>
                            <div class="rec-row" id="rec-cash-row">
                                <span>Tiền khách đưa:</span>
                                <span id="rec-cash">0 ₫</span>
                            </div>
                            <div class="rec-row" id="rec-change-row">
                                <span>Tiền thối lại:</span>
                                <strong id="rec-change">0 ₫</strong>
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
                    <button type="button" class="btn btn-secondary" onclick="closeModal('receipt-modal')">Đóng</button>
                    <button type="button" class="btn btn-primary" onclick="printReceipt('receipt-print-area')">🖨️ In Hóa Đơn</button>
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        var cart = [];
        var activeCategoryId = 0;

        function formatCurrency(num) {
            return Number(num || 0).toLocaleString('vi-VN') + ' ₫';
        }

        // Filter products by category
        function filterCategory(catId, btn) {
            activeCategoryId = catId;
            document.querySelectorAll('#pos-category-chips .chip').forEach(c => c.classList.remove('active'));
            if (btn) btn.classList.add('active');
            applyFilters();
        }

        // Search input handler
        document.getElementById('pos-search-input').addEventListener('input', function () {
            const clearBtn = document.getElementById('pos-search-clear');
            if (clearBtn) clearBtn.style.display = this.value ? 'block' : 'none';
            applyFilters();
        });

        // Quick Barcode Scanning Enter Press
        document.getElementById('pos-search-input').addEventListener('keydown', function (e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                const term = this.value.trim().toLowerCase();
                if (!term) return;

                // Find exact barcode match or exact code match
                const cards = document.querySelectorAll('.pos-product-card');
                for (let card of cards) {
                    const barcode = (card.dataset.barcode || '').toLowerCase();
                    const code = (card.dataset.code || '').toLowerCase();
                    if (barcode === term || code === term) {
                        addToCartFromElement(card);
                        this.value = '';
                        applyFilters();
                        return;
                    }
                }
            }
        });

        function clearSearch() {
            const input = document.getElementById('pos-search-input');
            input.value = '';
            document.getElementById('pos-search-clear').style.display = 'none';
            applyFilters();
            input.focus();
        }

        function applyFilters() {
            const term = (document.getElementById('pos-search-input').value || '').trim().toLowerCase();
            const cards = document.querySelectorAll('.pos-product-card');

            cards.forEach(card => {
                const name = (card.dataset.name || '').toLowerCase();
                const code = (card.dataset.code || '').toLowerCase();
                const barcode = (card.dataset.barcode || '').toLowerCase();
                const catId = parseInt(card.dataset.catId) || 0;

                const matchCat = (activeCategoryId === 0 || catId === activeCategoryId);
                const matchSearch = (!term || name.includes(term) || code.includes(term) || barcode.includes(term));

                if (matchCat && matchSearch) {
                    card.style.display = 'flex';
                } else {
                    card.style.display = 'none';
                }
            });
        }

        function addToCartFromElement(card) {
            const stock = parseInt(card.dataset.stock) || 0;
            if (stock <= 0) {
                showToast('Sản phẩm này đã hết hàng trong kho!', 'warning');
                return;
            }

            const item = {
                productId: parseInt(card.dataset.id),
                code: card.dataset.code,
                name: card.dataset.name,
                unit: card.dataset.unit,
                price: parseFloat(card.dataset.price),
                stock: stock
            };
            addToCart(item);
        }

        function addToCart(prod) {
            const existing = cart.find(i => i.productId === prod.productId);
            if (existing) {
                if (existing.quantity >= prod.stock) {
                    showToast(`Không thể thêm! Tồn kho chỉ còn ${prod.stock} ${prod.unit}.`, 'warning');
                    return;
                }
                existing.quantity++;
            } else {
                cart.push({
                    productId: prod.productId,
                    code: prod.code,
                    name: prod.name,
                    unit: prod.unit,
                    sellingPrice: prod.price,
                    stock: prod.stock,
                    quantity: 1
                });
            }
            renderCart();
        }

        function updateQuantity(productId, delta) {
            const item = cart.find(i => i.productId === productId);
            if (!item) return;

            const newQty = item.quantity + delta;
            if (newQty <= 0) {
                removeItem(productId);
                return;
            }
            if (newQty > item.stock) {
                showToast(`Chỉ còn ${item.stock} ${item.unit} trong kho!`, 'warning');
                return;
            }
            item.quantity = newQty;
            renderCart();
        }

        function removeItem(productId) {
            cart = cart.filter(i => i.productId !== productId);
            renderCart();
        }

        function clearCart() {
            if (cart.length === 0) return;
            cart = [];
            renderCart();
            showToast('Đã xóa giỏ hàng', 'info');
        }

        function renderCart() {
            const container = document.getElementById('cart-items-list');
            const countEl = document.getElementById('cart-item-count');
            countEl.textContent = cart.reduce((sum, i) => sum + i.quantity, 0);

            if (cart.length === 0) {
                container.innerHTML = `
                    <div class="empty-cart-message">
                        <div class="empty-cart-icon">🛒</div>
                        <p>Giỏ hàng đang trống</p>
                        <small class="text-muted">Nhấp vào sản phẩm bên trái hoặc quét mã vạch để thêm vào giỏ.</small>
                    </div>
                `;
                calculateTotals();
                return;
            }

            let html = '';
            cart.forEach(item => {
                const lineTotal = item.quantity * item.sellingPrice;
                html += `
                    <div class="cart-item">
                        <div class="cart-item-info">
                            <span class="cart-item-name">${item.name}</span>
                            <span class="cart-item-price">${formatCurrency(item.sellingPrice)} / ${item.unit}</span>
                        </div>
                        <div class="cart-item-controls">
                            <button type="button" class="btn-qty" onclick="updateQuantity(${item.productId}, -1)">−</button>
                            <span class="cart-item-qty">${item.quantity}</span>
                            <button type="button" class="btn-qty" onclick="updateQuantity(${item.productId}, 1)">+</button>
                            <span class="cart-item-total">${formatCurrency(lineTotal)}</span>
                            <button type="button" class="btn-remove" onclick="removeItem(${item.productId})" title="Xóa món">✕</button>
                        </div>
                    </div>
                `;
            });

            container.innerHTML = html;
            calculateTotals();
        }

        function calculateTotals() {
            let subtotal = 0;
            cart.forEach(i => subtotal += (i.quantity * i.sellingPrice));

            const discountInput = document.getElementById('cart-discount-input');
            const discount = Math.max(0, parseFloat(discountInput.value) || 0);
            const total = Math.max(0, subtotal - discount);

            document.getElementById('cart-subtotal').textContent = formatCurrency(subtotal);
            document.getElementById('cart-total-amount').textContent = formatCurrency(total);

            calculateChange();
        }

        function calculateChange() {
            let subtotal = 0;
            cart.forEach(i => subtotal += (i.quantity * i.sellingPrice));
            const discount = Math.max(0, parseFloat(document.getElementById('cart-discount-input').value) || 0);
            const total = Math.max(0, subtotal - discount);

            const paymentMethod = document.getElementById('cart-payment-method').value;
            const payInput = document.getElementById('cart-customer-payment');

            if (paymentMethod !== 'Tiền mặt') {
                document.getElementById('row-change-amount').style.display = 'none';
                return;
            } else {
                document.getElementById('row-change-amount').style.display = 'flex';
            }

            const paid = parseFloat(payInput.value) || 0;
            const change = Math.max(0, paid - total);
            document.getElementById('cart-change-amount').textContent = formatCurrency(change);
        }

        function setQuickCash(val) {
            let subtotal = 0;
            cart.forEach(i => subtotal += (i.quantity * i.sellingPrice));
            const discount = Math.max(0, parseFloat(document.getElementById('cart-discount-input').value) || 0);
            const total = Math.max(0, subtotal - discount);

            const payInput = document.getElementById('cart-customer-payment');
            if (val === 'exact') {
                payInput.value = total;
            } else {
                payInput.value = val;
            }
            calculateChange();
        }

        function onPaymentMethodChange() {
            const method = document.getElementById('cart-payment-method').value;
            const rowCash = document.getElementById('row-customer-payment');
            const pills = document.getElementById('quick-cash-pills');
            const rowChange = document.getElementById('row-change-amount');

            if (method === 'Tiền mặt') {
                rowCash.style.display = 'flex';
                pills.style.display = 'flex';
                rowChange.style.display = 'flex';
            } else {
                rowCash.style.display = 'none';
                pills.style.display = 'none';
                rowChange.style.display = 'none';
            }
            calculateChange();
        }

        function onCustomerChange() {
            const sel = document.getElementById('pos-customer-select');
            const opt = sel.options[sel.selectedIndex];
            const infoBox = document.getElementById('pos-customer-info');

            if (opt && opt.value) {
                const pts = opt.dataset.points || '0';
                const spent = parseFloat(opt.dataset.spent) || 0;
                document.getElementById('pos-cust-points').textContent = pts;
                document.getElementById('pos-cust-spent').textContent = formatCurrency(spent);
                infoBox.style.display = 'block';
            } else {
                infoBox.style.display = 'none';
            }
        }

        // Checkout action via PageMethods
        function performCheckout() {
            if (cart.length === 0) {
                showToast('Giỏ hàng đang trống, hãy chọn sản phẩm trước!', 'warning');
                return;
            }

            let subtotal = 0;
            cart.forEach(i => subtotal += (i.quantity * i.sellingPrice));
            const discount = Math.max(0, parseFloat(document.getElementById('cart-discount-input').value) || 0);
            const total = Math.max(0, subtotal - discount);

            const custVal = document.getElementById('pos-customer-select').value;
            const customerId = custVal ? parseInt(custVal) : 0;
            const empVal = document.getElementById('pos-employee-select').value;
            const employeeId = empVal ? parseInt(empVal) : 0;
            const paymentMethod = document.getElementById('cart-payment-method').value;

            let customerPayment = parseFloat(document.getElementById('cart-customer-payment').value) || total;
            if (paymentMethod !== 'Tiền mặt') {
                customerPayment = total;
            }

            if (paymentMethod === 'Tiền mặt' && customerPayment < total) {
                showToast('Số tiền khách đưa chưa đủ để thanh toán đơn hàng!', 'warning');
                return;
            }

            const checkoutData = {
                customerId: customerId,
                employeeId: employeeId,
                items: cart.map(i => ({
                    productId: i.productId,
                    name: i.name,
                    unit: i.unit,
                    sellingPrice: i.sellingPrice,
                    quantity: i.quantity
                })),
                discount: discount,
                customerPayment: customerPayment,
                paymentMethod: paymentMethod,
                notes: ''
            };

            const jsonStr = JSON.stringify(checkoutData);

            document.getElementById('btn-checkout').disabled = true;
            document.getElementById('btn-checkout').textContent = 'Đang xử lý thanh toán...';

            PageMethods.Checkout(jsonStr, function (result) {
                document.getElementById('btn-checkout').disabled = false;
                document.getElementById('btn-checkout').textContent = '⚡ THANH TOÁN & IN HÓA ĐƠN';

                const res = JSON.parse(result);
                if (res.Success) {
                    showToast('Thanh toán thành công!', 'success');
                    showReceiptModal(res.Invoice);
                    // Reset cart
                    cart = [];
                    renderCart();
                    document.getElementById('cart-discount-input').value = 0;
                    document.getElementById('cart-customer-payment').value = '';
                } else {
                    showToast(res.Error || 'Lỗi thanh toán!', 'error');
                }
            }, function (err) {
                document.getElementById('btn-checkout').disabled = false;
                document.getElementById('btn-checkout').textContent = '⚡ THANH TOÁN & IN HÓA ĐƠN';
                showToast('Lỗi máy chủ: ' + err.get_message(), 'error');
            });
        }

        function showReceiptModal(inv) {
            document.getElementById('rec-code').textContent = inv.Code;
            document.getElementById('rec-date').textContent = new Date().toLocaleString('vi-VN');
            document.getElementById('rec-employee').textContent = inv.EmployeeName || 'Thu ngân';
            document.getElementById('rec-customer').textContent = inv.CustomerName || 'Khách lẻ';

            const tbody = document.getElementById('rec-items-tbody');
            let rowsHtml = '';
            if (inv.Items) {
                inv.Items.forEach(it => {
                    rowsHtml += `
                        <tr>
                            <td class="td-item">${it.ProductName}</td>
                            <td class="td-qty text-center">${it.Quantity}</td>
                            <td class="td-price text-right">${formatCurrency(it.SellingPrice)}</td>
                            <td class="td-total text-right bold">${formatCurrency(it.TotalPrice)}</td>
                        </tr>
                    `;
                });
            }
            tbody.innerHTML = rowsHtml;

            document.getElementById('rec-subtotal').textContent = formatCurrency(inv.Subtotal);
            if (inv.Discount > 0) {
                document.getElementById('rec-discount-row').style.display = 'flex';
                document.getElementById('rec-discount').textContent = '-' + formatCurrency(inv.Discount);
            } else {
                document.getElementById('rec-discount-row').style.display = 'none';
            }
            document.getElementById('rec-total').textContent = formatCurrency(inv.TotalAmount);
            document.getElementById('rec-payment-method').textContent = inv.PaymentMethod;

            if (inv.PaymentMethod === 'Tiền mặt') {
                document.getElementById('rec-cash-row').style.display = 'flex';
                document.getElementById('rec-change-row').style.display = 'flex';
                document.getElementById('rec-cash').textContent = formatCurrency(inv.CustomerPayment);
                document.getElementById('rec-change').textContent = formatCurrency(inv.ChangeAmount);
            } else {
                document.getElementById('rec-cash-row').style.display = 'none';
                document.getElementById('rec-change-row').style.display = 'none';
            }

            openModal('receipt-modal');
        }
    </script>
</asp:Content>
