# 🏪 HỆ THỐNG QUẢN LÝ CỬA HÀNG TẠP HÓA (GROCERY STORE MANAGEMENT SYSTEM)

Hệ thống phần mềm toàn diện hỗ trợ chủ cửa hàng và nhân viên trong việc quản lý toàn bộ hoạt động kinh doanh hàng ngày của một cửa hàng tạp hóa / bách hóa / siêu thị mini.

Được xây dựng thuần với **HTML5, CSS3, JavaScript và Node.js** (sử dụng thư viện CSDL chuẩn `node:sqlite` tích hợp sẵn trong Node.js, không phụ thuộc thư viện ngoài - **Zero external dependencies**, khởi chạy tức thì).

---

## 📌 Các Phân Hệ & Chức Năng Chính

### 1. 📊 Tổng Quan & Thống Kê (Dashboard)
- **Doanh thu trong ngày** & số đơn hàng hoàn thành hôm nay.
- **Doanh thu trong tháng** & lợi nhuận gộp ước tính (Doanh thu - Giá vốn).
- **Tổng số đơn hàng** và **tổng số khách hàng** thành viên.
- **Số lượng sản phẩm đã bán** (toàn thời gian & hôm nay).
- **Tổng giá trị hàng tồn kho** (tổng vốn đang lưu kho).
- **Cảnh báo sản phẩm sắp hết hàng**: Tự động nhận diện các mặt hàng có tồn kho $\le$ mức cảnh báo định mức.
- **Biểu đồ doanh thu 7 ngày gần nhất**: Vẽ trực tiếp bằng Canvas HTML5 mượt mà.
- **Top sản phẩm bán chạy nhất**: Danh sách xếp hạng theo số lượng và doanh thu thu về.
- **Hóa đơn gần nhất**: Xem nhanh các giao dịch bán hàng vừa phát sinh.

### 2. 🛒 Quầy Thu Ngân Bán Hàng (POS Cashier)
- Phím tắt tiện lợi `F2` để mở nhanh màn hình bán hàng bất kỳ lúc nào.
- Tìm kiếm tức thì theo tên sản phẩm hoặc **quét mã vạch (Barcode)**.
- Phân nhóm hàng nhanh qua thanh Category Chips.
- Lưới sản phẩm trực quan hiển thị icon, giá bán và số lượng tồn thực tế.
- Giỏ hàng thông minh:
  - Tăng/giảm số lượng (+/-) hoặc gõ trực tiếp.
  - Kiểm tra tồn kho tự động (chặn không cho bán vượt số lượng tồn thực tế).
  - Chọn khách hàng thành viên (hiển thị điểm tích lũy & lịch sử chi tiêu).
  - Chọn nhân viên thu ngân trực ca.
  - Nhập chiết khấu / giảm giá đơn hàng.
  - Chọn hình thức thanh toán: Tiền mặt, Chuyển khoản QR, Thẻ ngân hàng.
  - Phím tính nhanh tiền khách đưa (Đúng số tiền, 50k, 100k, 200k, 500k) & tự động tính tiền thối lại.
- **Thanh toán & In hóa đơn**:
  - Tự động trừ kho của từng mặt hàng ngay khi thanh toán.
  - Tự động cộng điểm tích lũy cho khách hàng (10.000đ = 1 điểm).
  - Mở cửa sổ in hóa đơn định dạng K80 (máy in nhiệt siêu thị) hoặc in A5/A4 chuyên nghiệp.

### 3. 📦 Quản Lý Sản Phẩm (Products)
- Danh mục sản phẩm chi tiết: Mã SP, Barcode, Tên sản phẩm, Loại, Nhà cung cấp, ĐVT (gói, lon, chai, hộp, túi, kg...), Giá nhập (vốn), Giá bán, Tồn kho, Định mức cảnh báo, Biểu tượng/Icon.
- Bộ lọc kết hợp: Tìm kiếm theo tên/mã/barcode, lọc theo danh mục, lọc nhanh các sản phẩm sắp hết hàng.
- Thêm mới, chỉnh sửa và xóa sản phẩm.

### 4. 🏷️ Quản Lý Loại Sản Phẩm (Categories)
- Phân nhóm hàng hóa: Đồ uống, Mì & Ăn liền, Gia vị & Nước chấm, Sữa, Bánh kẹo, Hóa phẩm, Chăm sóc cá nhân, Lương thực & Đồ khô...
- Theo dõi số lượng mặt hàng thuộc từng nhóm.
- Thêm, sửa, xóa loại sản phẩm (có kiểm tra ràng buộc toàn vẹn dữ liệu).

### 5. 🏢 Quản Lý Kho Hàng & Kiểm Kê (Inventory Tracking)
- Thống kê kho: Tổng số mặt hàng, tổng số lượng đơn vị tồn, tổng giá trị vốn hàng tồn, số mặt hàng sắp hết, số mặt hàng đã hết.
- Lọc trạng thái tồn: Còn hàng, Sắp hết hàng, Hết hàng.
- **Chức năng Kiểm kê kho**:
  - Ghi nhận số lượng thực tế kiểm kê.
  - Chọn lý do: Kiểm kê định kỳ, Hao hụt / Rơi vỡ / Hỏng hóc, Hết hạn sử dụng, Tìm thấy hàng thất lạc...
  - Tự động cập nhật số tồn mới vào kho và lưu vào lịch sử kiểm kê.
- **Lịch sử kiểm kê**: Xem chi tiết các lần điều chỉnh tồn kho, chênh lệch (+ / -) và lý do.

### 6. 📥 Quản Lý Phiếu Nhập Hàng (Goods Receipts)
- Lập phiếu nhập hàng từ nhà phân phối / nhà cung cấp.
- Cho phép thêm nhiều mặt hàng vào cùng một phiếu nhập, nhập số lượng và đơn giá nhập tại thời điểm đó.
- Khi xác nhận phiếu nhập:
  - Tự động **cộng thêm số lượng tồn kho** của từng sản phẩm.
  - Tự động **cập nhật giá nhập mới nhất** cho sản phẩm.
- Xem danh sách và chi tiết các phiếu nhập hàng đã lập.

### 7. 🧾 Quản Lý Hóa Đơn Bán Hàng (Invoices)
- Danh sách toàn bộ hóa đơn bán hàng đã phát sinh.
- Lọc hóa đơn theo từ khóa (Mã HĐ, Tên khách hàng, SĐT) và khoảng thời gian (Từ ngày - Đến ngày).
- Xem chi tiết từng món hàng trong hóa đơn và **in lại hóa đơn (Re-print)** bất kỳ lúc nào.

### 8. 👥 Quản Lý Khách Hàng (Customers)
- Quản lý danh sách khách hàng thân thiết: Họ tên, Số điện thoại, Địa chỉ, Điểm tích lũy, Tổng chi tiêu.
- Thêm mới, sửa, xóa khách hàng. Tự động tích lũy điểm khi mua sắm tại quầy POS.

### 9. 🏭 Quản Lý Nhà Cung Cấp (Suppliers)
- Quản lý đối tác phân phối: Acecook, PepsiCo, Vinamilk, Unilever, Masan, Đại lý gạo...
- Lưu thông tin liên hệ, SĐT, Email, Địa chỉ, Ghi chú mặt hàng cung cấp.

### 10. 🧑‍💼 Quản Lý Nhân Viên (Employees)
- Danh sách nhân viên: Quản lý, Thu ngân, Nhân viên kho.
- Phân quyền thu ngân phục vụ ca bán hàng tại POS.

### 11. 📈 Báo Cáo & Phân Tích Kinh Doanh (Reports)
- Báo cáo doanh thu và sản lượng bán theo Loại sản phẩm kèm tỷ trọng %.
- Cơ cấu phương thức thanh toán (Tiền mặt, Chuyển khoản QR, Thẻ).
- Top 10 sản phẩm đạt doanh thu cao nhất và lợi nhuận gộp ước tính.

---

## 🚀 Cấu Trúc Dự Án

```
grocery-store-management/
├── package.json               # Cấu hình dự án & scripts khởi chạy
├── server.js                  # Máy chủ Node.js HTTP Server & REST API
├── db/
│   ├── database.js            # Khởi tạo CSDL SQLite & các bảng dữ liệu
│   ├── seed.js                # Dữ liệu mẫu ban đầu (23+ sản phẩm, danh mục, hóa đơn mẫu)
│   └── grocery.sqlite         # File CSDL SQLite (tự động tạo)
├── public/                    # Giao diện người dùng (HTML5 / CSS3 / Vanilla JS)
│   ├── index.html             # Trang giao diện chính (Single Page App)
│   ├── css/
│   │   ├── style.css          # Giao diện hiện đại, responsive, thẻ KPI, POS layout
│   │   └── print.css          # Tối ưu in hóa đơn nhiệt khổ K80 / A5
│   └── js/
│       ├── api.js             # Bộ xử lý gọi REST API
│       ├── app.js             # Điều hướng tab, đồng hồ, phím tắt F2, toast, modal
│       ├── dashboard.js       # Thống kê KPI, biểu đồ Canvas 7 ngày, top bán chạy
│       ├── pos.js             # Màn hình thu ngân, quét barcode, tính tiền, in HĐ
│       ├── products.js        # Quản lý Sản phẩm (CRUD, lọc, tìm kiếm)
│       ├── categories.js      # Quản lý Loại sản phẩm
│       ├── receipts.js        # Lập & xem Phiếu nhập hàng, tự động cộng kho
│       ├── invoices.js        # Lịch sử hóa đơn bán lẻ, in lại
│       ├── inventory.js       # Quản lý tồn kho & Kiểm kê điều chỉnh
│       ├── customers.js       # Quản lý Khách hàng & Điểm thưởng
│       ├── suppliers.js       # Quản lý Nhà cung cấp
│       ├── employees.js       # Quản lý Nhân viên
│       └── reports.js         # Báo cáo chuyên sâu doanh thu & tỷ trọng
└── README.md                  # Hướng dẫn chi tiết
```

---

## 🛠️ Hướng Dẫn Cài Đặt & Khởi Chạy

Dự án sử dụng module `node:sqlite` tích hợp sẵn trong Node.js 22+, **hoàn toàn không cần cài đặt thêm bất kỳ thư viện bên ngoài nào**.

### 1. Khởi chạy Server
Mở terminal tại thư mục dự án và chạy:
```bash
npm start
# hoặc: node server.js
```

### 2. Truy cập hệ thống
Mở trình duyệt web và truy cập địa chỉ:
```
http://localhost:3000
```

### 3. Khôi phục dữ liệu mẫu (Tùy chọn)
Nếu muốn nạp lại dữ liệu mẫu (sản phẩm tạp hóa Việt Nam thực tế, khách hàng, phiếu nhập và hóa đơn mẫu):
```bash
npm run seed
```
