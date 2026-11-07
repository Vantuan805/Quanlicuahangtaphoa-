# 🏪 HỆ THỐNG QUẢN LÝ CỬA HÀNG TẠP HÓA (ASP.NET WEB FORMS)

Dự án được xây dựng hoàn chỉnh theo chuẩn **ASP.NET Web Forms (C#)** trên nền tảng **.NET Framework 4.8 / 4.7.2** và cơ sở dữ liệu **Microsoft SQL Server / LocalDB**, kế thừa toàn bộ giao diện hiện đại, chuyên nghiệp cùng đầy đủ 11 phân hệ nghiệp vụ từ hệ thống quản lý tạp hóa thực tế.

---

## 📌 Các Phân Hệ & Chức Năng Chính

| STT | Trang ASPX | Tên Phân Hệ | Mô Tả Nghiệp Vụ |
| :---: | :--- | :--- | :--- |
| **1** | [`Default.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/Default.aspx) | **Tổng quan & Thống kê (Dashboard)** | 7 thẻ KPI (Doanh thu ngày, Doanh thu tháng & lãi ước tính, Hàng đã bán, Giá trị vốn tồn kho, Đơn hàng, Khách hàng, Cảnh báo sắp hết), biểu đồ Canvas doanh thu 7 ngày, Top 5 sản phẩm bán chạy, Hóa đơn gần nhất. |
| **2** | [`POS.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/POS.aspx) | **Quầy Thu Ngân (POS Cashier)** | Phím tắt **`F2`** mở màn hình POS. Quét Barcode / tìm theo tên, phân loại nhanh qua Category Chips, giỏ hàng tự động kiểm tra tồn kho không cho bán vượt tồn, chiết khấu, chọn khách hàng tích điểm (10.000đ = 1 điểm), chọn thu ngân trực ca, các phím tính nhanh tiền khách đưa, tính tiền thối lại, thanh toán và in hóa đơn nhiệt K80/A5. |
| **3** | [`Products.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/Products.aspx) | **Quản Lý Sản Phẩm** | Danh mục hàng hóa (Mã SP, Barcode, Tên SP, Loại, NCC, ĐVT, Giá nhập, Giá bán, Tồn kho, Mức cảnh báo, Icon emoji). Tìm kiếm từ khóa, lọc theo loại, lọc sắp hết, thêm/sửa/xóa qua modal. |
| **4** | [`Categories.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/Categories.aspx) | **Quản Lý Loại Sản Phẩm** | Phân nhóm hàng (Đồ uống, Mì ăn liền, Gia vị, Sữa, Bánh kẹo, Hóa phẩm, Chăm sóc cá nhân, Đồ khô). Thống kê số sản phẩm trong loại, CRUD và ràng buộc toàn vẹn khi xóa. |
| **5** | [`Suppliers.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/Suppliers.aspx) | **Quản Lý Nhà Cung Cấp** | Danh sách đối tác phân phối (Acecook, PepsiCo, Vinamilk, Unilever, Masan, Gạo miền Tây), liên hệ, email, địa chỉ và CRUD. |
| **6** | [`Customers.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/Customers.aspx) | **Quản Lý Khách Hàng** | Danh sách khách hàng thân thiết, theo dõi điểm thưởng tích lũy, tổng tiền đã chi tiêu, số điện thoại, địa chỉ và CRUD. |
| **7** | [`Employees.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/Employees.aspx) | **Quản Lý Nhân Viên** | Quản lý đội ngũ nhân viên: Phân vai trò Quản lý, Thu ngân, Nhân viên kho, trạng thái công việc (đang làm việc / nghỉ). |
| **8** | [`GoodsReceipts.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/GoodsReceipts.aspx) | **Quản Lý Phiếu Nhập Hàng** | Lập phiếu nhập kho từ nhà cung cấp, thêm nhiều mặt hàng vào cùng một phiếu, nhập số lượng và giá vốn. Khi xác nhận, hệ thống tự động **cộng dồn tồn kho** và **cập nhật giá vốn mới nhất**. Hỗ trợ xem chi tiết phiếu nhập. |
| **9** | [`Invoices.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/Invoices.aspx) | **Quản Lý Hóa Đơn Bán Lẻ** | Danh sách hóa đơn bán hàng, lọc theo mã hóa đơn, tên/SĐT khách hàng, khoảng ngày (Từ ngày - Đến ngày). Xem chi tiết từng món hàng và in lại hóa đơn (Re-print). |
| **10** | [`Inventory.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/Inventory.aspx) | **Kho Hàng & Kiểm Kê** | Thống kê kho hàng, lọc trạng thái (Còn hàng, Sắp hết, Hết hàng). Chức năng **Phiếu kiểm kê điều chỉnh** ghi nhận số lượng thực tế với các lý do (Kiểm kê định kỳ, Hao hụt/Rơi vỡ, Hết hạn, Thất lạc...). Lưu lịch sử kiểm kê chi tiết. |
| **11** | [`Reports.aspx`](file:///C:/Users/thang/.gemini/antigravity/scratch/QuanLiCuaHangTapHoa_WebForms/Reports.aspx) | **Báo Cáo & Phân Tích** | Doanh thu & sản lượng theo loại sản phẩm kèm thanh tỷ trọng %, cơ cấu phương thức thanh toán (Tiền mặt, QR, Thẻ), Top 10 sản phẩm doanh thu cao & tỷ suất lãi gộp. |

---

## 🚀 Cấu Trúc Thư Mục Dự Án

```
QuanLiCuaHangTapHoa_WebForms/
├── App_Data/
│   ├── init_db.ps1            # Script nạp CSDL tự động qua PowerShell
│   └── test_all_pages.ps1     # Script kiểm thử tự động toàn bộ 11 trang
├── bin/
│   ├── QuanLiCuaHangTapHoa.dll # DLL sau khi biên dịch
│   └── QuanLiCuaHangTapHoa.pdb
├── Content/
│   ├── style.css              # Giao diện hiện đại, responsive, thẻ KPI, POS layout
│   └── print.css              # Định dạng in hóa đơn nhiệt K80 / A5
├── DAL/
│   └── DatabaseHelper.cs      # Lớp truy xuất CSDL ADO.NET, Parameterized Query, Transaction
├── Models/
│   └── Models.cs              # Định nghĩa toàn bộ thực thể Entity & CartItem
├── Properties/
├── Scripts/
│   └── app.js                 # Đồng hồ thời gian thực, Toast thông báo, Modal, In ấn, Phím tắt F2
├── Site.Master                # Giao diện khung dùng chung (MasterPage)
├── Site.Master.cs
├── Site.Master.designer.cs
├── Global.asax                # Cấu hình ứng dụng toàn cục
├── Global.asax.cs
├── Default.aspx               # 📊 Phân hệ Tổng quan & Thống kê
├── Default.aspx.cs
├── Default.aspx.designer.cs
├── POS.aspx                   # 🛒 Phân hệ Bán hàng thu ngân POS
├── POS.aspx.cs
├── POS.aspx.designer.cs
├── Products.aspx              # 📦 Phân hệ Quản lý sản phẩm
├── Categories.aspx            # 🏷️ Phân hệ Loại sản phẩm
├── Suppliers.aspx             # 🏭 Phân hệ Nhà cung cấp
├── Customers.aspx             # 👥 Phân hệ Khách hàng
├── Employees.aspx             # 🧑‍💼 Phân hệ Nhân viên
├── GoodsReceipts.aspx         # 📥 Phân hệ Phiếu nhập kho
├── Invoices.aspx              # 🧾 Phân hệ Hóa đơn bán lẻ
├── Inventory.aspx             # 🏢 Phân hệ Kho hàng & Kiểm kê
├── Reports.aspx               # 📈 Phân hệ Báo cáo kinh doanh
├── Web.config                 # Chuỗi kết nối CSDL và cấu hình ASP.NET
├── Database.sql               # Script tạo Database & nạp đầy đủ dữ liệu mẫu tiếng Việt
├── QuanLiCuaHangTapHoa.csproj # Project file Visual Studio
├── QuanLiCuaHangTapHoa.sln    # Solution file Visual Studio
├── run_server.bat             # File chạy tức thì với IIS Express & tự mở trình duyệt
└── README.md
