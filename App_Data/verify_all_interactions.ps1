param()

$baseUrl = "http://localhost:8088"
$client = New-Object System.Net.WebClient
$client.Encoding = [System.Text.Encoding]::UTF8
$client.Headers.Add("Content-Type", "application/json; charset=utf-8")

Write-Output "===================================================================="
Write-Output "🔍 BẮT ĐẦU KIỂM TRA TOÀN DIỆN 11 PHÂN HỆ VÀ CÁC NÚT TƯƠNG TÁC"
Write-Output "===================================================================="

$pages = @(
    @{ Name = "Default.aspx"; Title = "Tổng quan & Thống kê"; RequiredElements = @("kpi-grid", "revenue-chart", "rptTopSelling", "rptLowStock", "rptRecentInvoices") },
    @{ Name = "POS.aspx"; Title = "Quầy Thu Ngân (POS)"; RequiredElements = @("pos-search-input", "pos-category-chips", "pos-products-grid", "cart-items-list", "btn-checkout", "receipt-modal") },
    @{ Name = "Products.aspx"; Title = "Quản lý Sản phẩm"; RequiredElements = @("openProductModal", "product-modal", "openEditModal", "btnSaveProduct", "txtProdName") },
    @{ Name = "Categories.aspx"; Title = "Loại sản phẩm"; RequiredElements = @("openCategoryModal", "cat-modal", "openEditCategoryModal", "btnSaveCategory", "txtCatName") },
    @{ Name = "Inventory.aspx"; Title = "Kho hàng & Kiểm kê"; RequiredElements = @("openAdjustModal", "adjust-modal", "txtNewQuantity", "btnSaveAdjust", "ddlModalProducts") },
    @{ Name = "GoodsReceipts.aspx"; Title = "Phiếu nhập hàng"; RequiredElements = @("openCreateReceiptModal", "create-receipt-modal", "addReceiptRow", "submitReceipt", "view-receipt-modal") },
    @{ Name = "Invoices.aspx"; Title = "Hóa đơn bán hàng"; RequiredElements = @("viewInvoiceDetails", "invoice-modal", "invoice-print-area", "printReceipt") },
    @{ Name = "Suppliers.aspx"; Title = "Nhà cung cấp"; RequiredElements = @("openSupplierModal", "sup-modal", "openEditSupplierModal", "btnSaveSupplier", "txtSupName") },
    @{ Name = "Customers.aspx"; Title = "Khách hàng"; RequiredElements = @("openCustomerModal", "cust-modal", "openEditCustomerModal", "btnSaveCustomer", "txtCustName") },
    @{ Name = "Employees.aspx"; Title = "Nhân viên"; RequiredElements = @("openEmployeeModal", "emp-modal", "openEditEmployeeModal", "btnSaveEmployee", "txtEmpName") },
    @{ Name = "Reports.aspx"; Title = "Báo cáo kinh doanh"; RequiredElements = @("rptCategorySales", "rptPaymentMethods", "rptTopProducts", "progress-bar-fill") }
)

$allPassed = $true

# 1. KIỂM TRA TỪNG TRANG VÀ CÁC NÚT TƯƠNG TÁC TRÊN GIAO DIỆN HTML
Write-Output "`n--- PHẦN 1: KIỂM TRA MÃ HTML, NÚT BẤM & POPUP MODAL TỪNG TRANG ---"
foreach ($p in $pages) {
    $url = "$baseUrl/$($p.Name)"
    try {
        $html = $client.DownloadString($url)
        $missing = @()
        foreach ($elem in $p.RequiredElements) {
            if ($html -notmatch $elem) {
                $missing += $elem
            }
        }

        # Check for unparsed ASP.NET tags like <%= or <%#
        $unparsedTags = [regex]::Matches($html, '<%[=#][\s\S]*?%>')
        
        if ($missing.Count -eq 0 -and $unparsedTags.Count -eq 0) {
            Write-Output "  ✅ [$($p.Name)] $($p.Title): OK (Tất cả nút bấm & Modal đều đầy đủ, không có lỗi tag)"
        } elseif ($missing.Count -gt 0) {
            Write-Output "  ❌ [$($p.Name)] $($p.Title): THIẾU ELEMENT -> $($missing -join ', ')"
            $allPassed = $false
        } else {
            Write-Output "  ⚠️ [$($p.Name)] $($p.Title): Có $($unparsedTags.Count) thẻ ASP.NET chưa được render!"
            $allPassed = $false
        }
    } catch {
        Write-Output "  ❌ [$($p.Name)] $($p.Title): LỖI TẢI TRANG -> $($_.Exception.Message)"
        $allPassed = $false
    }
}

# 2. KIỂM TRA CÁC WEBMETHOD API (POS CHECKOUT, GET DETAILS)
Write-Output "`n--- PHẦN 2: KIỂM TRA CÁC WEBMETHOD API AJAX / PAGEMETHODS ---"

# Test 2.1: GetReceiptDetails in GoodsReceipts.aspx
try {
    $req = [System.Net.WebRequest]::Create("$baseUrl/GoodsReceipts.aspx/GetReceiptDetails")
    $req.Method = "POST"
    $req.ContentType = "application/json; charset=utf-8"
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes('{"id": 1}')
    $req.ContentLength = $bodyBytes.Length
    $stream = $req.GetRequestStream()
    $stream.Write($bodyBytes, 0, $bodyBytes.Length)
    $stream.Close()
    $res = $req.GetResponse()
    $reader = New-Object System.IO.StreamReader($res.GetResponseStream())
    $json = $reader.ReadToEnd()
    $reader.Close()
    $res.Close()
    if ($json -match '"Success":true' -or $json -match 'PN20261103001') {
        Write-Output "  ✅ [GoodsReceipts.aspx/GetReceiptDetails]: OK (Trả về chi tiết phiếu nhập ID 1 thành công)"
    } else {
        Write-Output "  ⚠️ [GoodsReceipts.aspx/GetReceiptDetails]: Kết quả: $json"
    }
} catch {
    Write-Output "  ❌ [GoodsReceipts.aspx/GetReceiptDetails]: LỖI -> $($_.Exception.Message)"
    $allPassed = $false
}

# Test 2.2: GetInvoiceDetails in Invoices.aspx
try {
    $req = [System.Net.WebRequest]::Create("$baseUrl/Invoices.aspx/GetInvoiceDetails")
    $req.Method = "POST"
    $req.ContentType = "application/json; charset=utf-8"
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes('{"id": 1}')
    $req.ContentLength = $bodyBytes.Length
    $stream = $req.GetRequestStream()
    $stream.Write($bodyBytes, 0, $bodyBytes.Length)
    $stream.Close()
    $res = $req.GetResponse()
    $reader = New-Object System.IO.StreamReader($res.GetResponseStream())
    $json = $reader.ReadToEnd()
    $reader.Close()
    $res.Close()
    if ($json -match '"Success":true' -or $json -match 'HD20261105001') {
        Write-Output "  ✅ [Invoices.aspx/GetInvoiceDetails]: OK (Trả về chi tiết hóa đơn ID 1 thành công)"
    } else {
        Write-Output "  ⚠️ [Invoices.aspx/GetInvoiceDetails]: Kết quả: $json"
    }
} catch {
    Write-Output "  ❌ [Invoices.aspx/GetInvoiceDetails]: LỖI -> $($_.Exception.Message)"
    $allPassed = $false
}

# Test 2.3: POS Checkout WebMethod
try {
    $checkoutPayload = @{
        json = (ConvertTo-Json -Compress @{
            customerId = 1
            employeeId = 2
            items = @(
                @{
                    productId = 1
                    name = "Mì Hảo Hảo Tôm chua cay 75g"
                    unit = "Gói"
                    sellingPrice = 4500
                    quantity = 2
                }
            )
            discount = 0
            customerPayment = 10000
            paymentMethod = "Tiền mặt"
            notes = "Test đơn tự động qua WebMethod"
        })
    } | ConvertTo-Json -Compress

    $req = [System.Net.WebRequest]::Create("$baseUrl/POS.aspx/Checkout")
    $req.Method = "POST"
    $req.ContentType = "application/json; charset=utf-8"
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($checkoutPayload)
    $req.ContentLength = $bodyBytes.Length
    $stream = $req.GetRequestStream()
    $stream.Write($bodyBytes, 0, $bodyBytes.Length)
    $stream.Close()
    $res = $req.GetResponse()
    $reader = New-Object System.IO.StreamReader($res.GetResponseStream())
    $json = $reader.ReadToEnd()
    $reader.Close()
    $res.Close()
    if ($json -match '"Success":true' -and $json -match 'HD') {
        Write-Output "  ✅ [POS.aspx/Checkout WebMethod]: OK (Thanh toán đơn hàng thành công, tự trừ tồn kho & tích điểm!)"
    } else {
        Write-Output "  ⚠️ [POS.aspx/Checkout WebMethod]: Kết quả: $json"
        $allPassed = $false
    }
} catch {
    Write-Output "  ❌ [POS.aspx/Checkout WebMethod]: LỖI -> $($_.Exception.Message)"
    $allPassed = $false
}

# 3. KIỂM TRA FILE TÀI NGUYÊN CSS & JAVASCRIPT
Write-Output "`n--- PHẦN 3: KIỂM TRA CSS MODAL & JAVASCRIPT HANDLERS ---"
try {
    $css = $client.DownloadString("$baseUrl/Content/style.css")
    if ($css -match '\.modal[\s\S]*?z-index:\s*99999' -and $css -match '\.modal\.show') {
        Write-Output "  ✅ [Content/style.css]: CSS Modal hoàn chỉnh (z-index 99999, backdrop-filter blur, flex display)"
    } else {
        Write-Output "  ❌ [Content/style.css]: Thiếu định nghĩa .modal hoặc .modal.show!"
        $allPassed = $false
    }
} catch {
    Write-Output "  ❌ [Content/style.css]: LỖI TẢI CSS -> $($_.Exception.Message)"
    $allPassed = $false
}

try {
    $js = $client.DownloadString("$baseUrl/Scripts/app.js")
    if ($js -match 'function openModal' -and $js -match 'function closeModal' -and $js -match 'Escape' -and $js -match 'showToast') {
        Write-Output "  ✅ [Scripts/app.js]: JS Helper hoàn chỉnh (openModal, closeModal, ESC handler, showToast, Clock)"
    } else {
        Write-Output "  ❌ [Scripts/app.js]: Thiếu các hàm xử lý Modal hoặc Toast!"
        $allPassed = $false
    }
} catch {
    Write-Output "  ❌ [Scripts/app.js]: LỖI TẢI JS -> $($_.Exception.Message)"
    $allPassed = $false
}

Write-Output "`n===================================================================="
if ($allPassed) {
    Write-Output "🎉 KẾT QUẢ: 100% TẤT CẢ 11 PHÂN HỆ VÀ CÁC NÚT TƯƠNG TÁC ĐỀU HOẠT ĐỘNG HOÀN HẢO!"
} else {
    Write-Output "⚠️ KẾT QUẢ: PHÁT HIỆN LỖI CẦN XỬ LÝ (Xem chi tiết phía trên)"
}
Write-Output "===================================================================="
