-- ==============================================================
-- CƠ SỞ DỮ LIỆU: QUẢN LÝ CỬA HÀNG TẠP HÓA (GROCERY STORE MANAGEMENT)
-- HỆ QUẢN TRỊ: MICROSOFT SQL SERVER / LOCALDB / SQL EXPRESS
-- ==============================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'QuanLiCuaHangTapHoa')
BEGIN
    CREATE DATABASE QuanLiCuaHangTapHoa;
END
GO

USE QuanLiCuaHangTapHoa;
GO

-- 1. BẢNG LOẠI SẢN PHẨM (Categories)
IF OBJECT_ID('dbo.Categories', 'U') IS NULL
BEGIN
    CREATE TABLE Categories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL UNIQUE,
        Name NVARCHAR(150) NOT NULL,
        Description NVARCHAR(500) NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- 2. BẢNG NHÀ CUNG CẤP (Suppliers)
IF OBJECT_ID('dbo.Suppliers', 'U') IS NULL
BEGIN
    CREATE TABLE Suppliers (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL UNIQUE,
        Name NVARCHAR(150) NOT NULL,
        Phone NVARCHAR(50) NULL,
        Email NVARCHAR(100) NULL,
        Address NVARCHAR(250) NULL,
        Notes NVARCHAR(500) NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- 3. BẢNG KHÁCH HÀNG (Customers)
IF OBJECT_ID('dbo.Customers', 'U') IS NULL
BEGIN
    CREATE TABLE Customers (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL UNIQUE,
        Name NVARCHAR(150) NOT NULL,
        Phone NVARCHAR(50) NULL,
        Address NVARCHAR(250) NULL,
        Points INT DEFAULT 0,
        TotalSpent DECIMAL(18,2) DEFAULT 0,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- 4. BẢNG NHÂN VIÊN (Employees)
IF OBJECT_ID('dbo.Employees', 'U') IS NULL
BEGIN
    CREATE TABLE Employees (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL UNIQUE,
        Name NVARCHAR(150) NOT NULL,
        Phone NVARCHAR(50) NULL,
        Role NVARCHAR(50) NOT NULL DEFAULT N'Thu ngân',
        Status NVARCHAR(50) NOT NULL DEFAULT N'active',
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- 5. BẢNG SẢN PHẨM (Products)
IF OBJECT_ID('dbo.Products', 'U') IS NULL
BEGIN
    CREATE TABLE Products (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL UNIQUE,
        Barcode NVARCHAR(50) NULL,
        Name NVARCHAR(200) NOT NULL,
        CategoryId INT NULL FOREIGN KEY REFERENCES Categories(Id) ON DELETE SET NULL,
        SupplierId INT NULL FOREIGN KEY REFERENCES Suppliers(Id) ON DELETE SET NULL,
        Unit NVARCHAR(50) NOT NULL DEFAULT N'Cái',
        CostPrice DECIMAL(18,2) NOT NULL DEFAULT 0,
        SellingPrice DECIMAL(18,2) NOT NULL DEFAULT 0,
        StockQuantity INT NOT NULL DEFAULT 0,
        MinStockAlert INT NOT NULL DEFAULT 10,
        ImageIcon NVARCHAR(50) DEFAULT N'📦',
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- 6. BẢNG PHIẾU NHẬP HÀNG (Goods Receipts)
IF OBJECT_ID('dbo.GoodsReceipts', 'U') IS NULL
BEGIN
    CREATE TABLE GoodsReceipts (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL UNIQUE,
        SupplierId INT NULL FOREIGN KEY REFERENCES Suppliers(Id) ON DELETE SET NULL,
        EmployeeId INT NULL FOREIGN KEY REFERENCES Employees(Id) ON DELETE SET NULL,
        TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        Notes NVARCHAR(500) NULL,
        ReceiptDate DATETIME DEFAULT GETDATE(),
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- 7. BẢNG CHI TIẾT PHIẾU NHẬP (Goods Receipt Details)
IF OBJECT_ID('dbo.GoodsReceiptDetails', 'U') IS NULL
BEGIN
    CREATE TABLE GoodsReceiptDetails (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ReceiptId INT NOT NULL FOREIGN KEY REFERENCES GoodsReceipts(Id) ON DELETE CASCADE,
        ProductId INT NOT NULL FOREIGN KEY REFERENCES Products(Id),
        Quantity INT NOT NULL,
        CostPrice DECIMAL(18,2) NOT NULL,
        TotalPrice DECIMAL(18,2) NOT NULL
    );
END
GO

-- 8. BẢNG HÓA ĐƠN BÁN HÀNG (Invoices)
IF OBJECT_ID('dbo.Invoices', 'U') IS NULL
BEGIN
    CREATE TABLE Invoices (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL UNIQUE,
        CustomerId INT NULL FOREIGN KEY REFERENCES Customers(Id) ON DELETE SET NULL,
        EmployeeId INT NULL FOREIGN KEY REFERENCES Employees(Id) ON DELETE SET NULL,
        Subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
        Discount DECIMAL(18,2) NOT NULL DEFAULT 0,
        TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        CustomerPayment DECIMAL(18,2) NOT NULL DEFAULT 0,
        ChangeAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        PaymentMethod NVARCHAR(50) NOT NULL DEFAULT N'Tiền mặt',
        Notes NVARCHAR(500) NULL,
        InvoiceDate DATETIME DEFAULT GETDATE(),
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- 9. BẢNG CHI TIẾT HÓA ĐƠN (Invoice Details)
IF OBJECT_ID('dbo.InvoiceDetails', 'U') IS NULL
BEGIN
    CREATE TABLE InvoiceDetails (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        InvoiceId INT NOT NULL FOREIGN KEY REFERENCES Invoices(Id) ON DELETE CASCADE,
        ProductId INT NOT NULL FOREIGN KEY REFERENCES Products(Id),
        ProductName NVARCHAR(200) NOT NULL,
        Unit NVARCHAR(50) NOT NULL,
        Quantity INT NOT NULL,
        CostPrice DECIMAL(18,2) NOT NULL DEFAULT 0,
        SellingPrice DECIMAL(18,2) NOT NULL,
        TotalPrice DECIMAL(18,2) NOT NULL
    );
END
GO

-- 10. BẢNG KIỂM KÊ / ĐIỀU CHỈNH KHO (Stock Adjustments)
IF OBJECT_ID('dbo.StockAdjustments', 'U') IS NULL
BEGIN
    CREATE TABLE StockAdjustments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL UNIQUE,
        ProductId INT NOT NULL FOREIGN KEY REFERENCES Products(Id),
        OldQuantity INT NOT NULL,
        NewQuantity INT NOT NULL,
        ChangeQuantity INT NOT NULL,
        Reason NVARCHAR(250) NULL,
        EmployeeId INT NULL FOREIGN KEY REFERENCES Employees(Id) ON DELETE SET NULL,
        AdjustedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- ==============================================================
-- DỮ LIỆU MẪU (SEED DATA)
-- ==============================================================

-- 1. Thêm Loại sản phẩm
IF NOT EXISTS (SELECT 1 FROM Categories)
BEGIN
    INSERT INTO Categories (Code, Name, Description) VALUES
    (N'LSP01', N'Đồ uống & Nước giải khát', N'Nước ngọt, nước suối, bia, nước tăng lực'),
    (N'LSP02', N'Mì & Thực phẩm ăn liền', N'Mì gói, phở, bún miến, cháo ăn liền, xúc xích'),
    (N'LSP03', N'Gia vị & Nước chấm', N'Nước mắm, dầu ăn, hạt nêm, bột ngọt, tương ớt'),
    (N'LSP04', N'Sữa & Chế phẩm sữa', N'Sữa tươi, sữa đặc, sữa chua, phô mai'),
    (N'LSP05', N'Bánh kẹo & Snack', N'Bánh quy, kẹo, bim bim, bánh ngọt'),
    (N'LSP06', N'Hóa phẩm & Tẩy rửa', N'Bột giặt, nước rửa chén, nước xả, lau sàn'),
    (N'LSP07', N'Chăm sóc cá nhân', N'Dầu gội, sữa tắm, kem đánh răng, xà phòng'),
    (N'LSP08', N'Gạo & Đồ khô', N'Gạo sạch, đường cát, các loại đậu, trứng gà vịt');
END
GO

-- 2. Thêm Nhà cung cấp
IF NOT EXISTS (SELECT 1 FROM Suppliers)
BEGIN
    INSERT INTO Suppliers (Code, Name, Phone, Email, Address, Notes) VALUES
    (N'NCC01', N'Công ty CP Acecook Việt Nam', N'02838154064', N'lienhe@acecookvietnam.com', N'KCN Tân Bình, Tây Thạnh, Tân Phú, TP.HCM', N'NCC mì tôm chính hãng'),
    (N'NCC02', N'Công ty TNHH Suntory PepsiCo VN', N'02838219468', N'sales@suntorypepsico.vn', N'Tầng 5 Sheraton Saigon, Q.1, TP.HCM', N'NCC nước ngọt, Sting, Aquafina'),
    (N'NCC03', N'Công ty CP Sữa Việt Nam (Vinamilk)', N'1900636979', N'vinamilk@vinamilk.com.vn', N'Số 10 Tân Trào, Tân Phú, Q.7, TP.HCM', N'NCC sữa chua, sữa tươi'),
    (N'NCC04', N'Công ty TNHH Unilever Việt Nam', N'02854135686', N'unilever@unilever.com.vn', N'156 Nguyễn Lương Bằng, Q.7, TP.HCM', N'NCC OMO, Sunlight, Clear, P/S'),
    (N'NCC05', N'Công ty CP Hàng tiêu dùng Masan', N'02862563862', N'contact@masangroup.com', N'Mplaza Saigon, Lê Duẩn, Q.1, TP.HCM', N'NCC Chinsu, Nam Ngư, Omachi'),
    (N'NCC06', N'Đại lý Gạo Sạch Miền Tây', N'0908123456', N'gaomientay@gmail.com', N'128 Quốc Lộ 1A, Tiền Giang', N'NCC gạo ST25, gạo thơm lài');
END
GO

-- 3. Thêm Nhân viên
IF NOT EXISTS (SELECT 1 FROM Employees)
BEGIN
    INSERT INTO Employees (Code, Name, Phone, Role, Status) VALUES
    (N'NV01', N'Nguyễn Văn Quản', N'0912345678', N'Quản lý', N'active'),
    (N'NV02', N'Trần Thị Mai', N'0987654321', N'Thu ngân', N'active'),
    (N'NV03', N'Lê Hoàng Nam', N'0903112233', N'Nhân viên kho', N'active');
END
GO

-- 4. Thêm Khách hàng
IF NOT EXISTS (SELECT 1 FROM Customers)
BEGIN
    INSERT INTO Customers (Code, Name, Phone, Address, Points, TotalSpent) VALUES
    (N'KH01', N'Chị Nguyễn Thị Lan', N'0909111222', N'Số 12 Đường Số 5, P.7, Gò Vấp', 125, 1250000),
    (N'KH02', N'Anh Trần Minh Tuấn', N'0918222333', N'Số 45 Lê Lợi, P. Bến Nghé, Q.1', 85, 850000),
    (N'KH03', N'Cô Ba Hạnh', N'0933444555', N'Hẻm 88 Nguyễn Trãi, P.3, Q.5', 210, 2100000),
    (N'KH04', N'Bác Hoàng Năm', N'0977888999', N'Số 15 Hoàng Hoa Thám, Bình Thạnh', 45, 450000);
END
GO

-- 5. Thêm Sản phẩm
IF NOT EXISTS (SELECT 1 FROM Products)
BEGIN
    INSERT INTO Products (Code, Barcode, Name, CategoryId, SupplierId, Unit, CostPrice, SellingPrice, StockQuantity, MinStockAlert, ImageIcon) VALUES
    (N'SP001', N'8934563138164', N'Mì Hảo Hảo Tôm chua cay 75g', 2, 1, N'Gói', 3800, 4500, 150, 20, N'🍜'),
    (N'SP002', N'8936079121785', N'Mì Omachi Sườn hầm ngũ quả 80g', 2, 5, N'Gói', 7500, 9000, 85, 15, N'🍜'),
    (N'SP003', N'8935049500544', N'Nước ngọt Coca Cola 320ml', 1, 2, N'Lon', 8500, 10000, 48, 12, N'🥤'),
    (N'SP004', N'8934588012111', N'Nước ngọt Pepsi lon 320ml', 1, 2, N'Lon', 8200, 10000, 42, 12, N'🥤'),
    (N'SP005', N'8934588012222', N'Nước khoáng Aquafina 500ml', 1, 2, N'Chai', 4000, 5500, 60, 15, N'💧'),
    (N'SP006', N'8934561240012', N'Nước mắm Nam Ngư Đệ Nhị 900ml', 3, 5, N'Chai', 22000, 28000, 24, 6, N'🏺'),
    (N'SP007', N'8934673129871', N'Dầu ăn Tường An Cooking Oil 1L', 3, 5, N'Chai', 43000, 52000, 18, 5, N'🛢️'),
    (N'SP008', N'8936079120021', N'Nước tương Chinsu Nấm Shiitake 330ml', 3, 5, N'Chai', 18000, 23000, 20, 5, N'🏺'),
    (N'SP009', N'8934673554412', N'Hạt nêm Knorr Thịt thăn 400g', 3, 4, N'Gói', 31000, 38000, 16, 5, N'🧂'),
    (N'SP010', N'8934673667789', N'Bột ngọt Ajinomoto 454g', 3, 5, N'Gói', 32000, 39000, 15, 5, N'🧂'),
    (N'SP011', N'8934673889911', N'Sữa tươi Vinamilk có đường 180ml', 4, 3, N'Lốc (4)', 28000, 34000, 35, 8, N'🥛'),
    (N'SP012', N'8934673998822', N'Sữa chua Vinamilk có đường 100g', 4, 3, N'Lốc (4)', 24000, 29000, 22, 6, N'🍨'),
    (N'SP013', N'8936036010014', N'Bánh Chocopie Orion hộp 12 cái', 5, 1, N'Hộp', 48000, 58000, 12, 4, N'🥧'),
    (N'SP014', N'8936036020025', N'Snack Oishi Tôm cay 40g', 5, 1, N'Gói', 5000, 6500, 45, 10, N'🍿'),
    (N'SP015', N'8934868112233', N'Bột giặt OMO Matic Cửa trên 3kg', 6, 4, N'Túi', 175000, 210000, 8, 3, N'🧺'),
    (N'SP016', N'8934868223344', N'Nước rửa chén Sunlight Chanh 750g', 6, 4, N'Chai', 23000, 29000, 19, 5, N'🧴'),
    (N'SP017', N'8934868334455', N'Dầu gội Clear Bạc hà 650g', 7, 4, N'Chai', 155000, 185000, 9, 3, N'🧴'),
    (N'SP018', N'8934868445566', N'Kem đánh răng P/S Bảo vệ 123 200g', 7, 4, N'Hộp', 26000, 33000, 25, 6, N'🪥'),
    (N'SP019', N'8938501234567', N'Gạo thơm ST25 Ông Cua túi 5kg', 8, 6, N'Túi', 165000, 195000, 14, 5, N'🌾'),
    (N'SP020', N'8938502345678', N'Trứng gà tươi Ba Huân (Hộp 10)', 8, 6, N'Hộp', 27000, 33000, 4, 10, N'🥚'),
    (N'SP021', N'8934588019999', N'Nước tăng lực Red Bull 250ml', 1, 2, N'Lon', 11500, 14000, 3, 15, N'⚡'),
    (N'SP022', N'8936079128888', N'Xúc xích tiệt trùng Vissan 4 cây', 2, 5, N'Gói', 16000, 20000, 5, 10, N'🌭'),
    (N'SP023', N'8934588033333', N'Bia Tiger lon 330ml', 1, 2, N'Lon', 16500, 19500, 72, 24, N'🍺');
END
GO

-- 6. Thêm Phiếu nhập hàng mẫu (Goods Receipts)
IF NOT EXISTS (SELECT 1 FROM GoodsReceipts)
BEGIN
    INSERT INTO GoodsReceipts (Code, SupplierId, EmployeeId, TotalAmount, Notes, ReceiptDate)
    VALUES (N'PN20261103001', 1, 3, 570000, N'Nhập mì tôm và bánh kẹo', DATEADD(DAY, -2, GETDATE()));
    DECLARE @R1 INT = SCOPE_IDENTITY();
    INSERT INTO GoodsReceiptDetails (ReceiptId, ProductId, Quantity, CostPrice, TotalPrice) VALUES
    (@R1, 1, 100, 3800, 380000),
    (@R1, 14, 38, 5000, 190000);

    INSERT INTO GoodsReceipts (Code, SupplierId, EmployeeId, TotalAmount, Notes, ReceiptDate)
    VALUES (N'PN20261104001', 2, 3, 1269000, N'Nhập nước giải khát Pepsi, Aquafina, Tiger', DATEADD(DAY, -1, GETDATE()));
    DECLARE @R2 INT = SCOPE_IDENTITY();
    INSERT INTO GoodsReceiptDetails (ReceiptId, ProductId, Quantity, CostPrice, TotalPrice) VALUES
    (@R2, 3, 48, 8500, 408000),
    (@R2, 5, 50, 4000, 200000),
    (@R2, 23, 40, 16500, 661000);
END
GO

-- 7. Thêm Hóa đơn bán hàng mẫu (Invoices & Details)
IF NOT EXISTS (SELECT 1 FROM Invoices)
BEGIN
    -- Hóa đơn 1 (Hôm nay)
    INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
    VALUES (N'HD20261105001', 1, 2, 147500, 0, 147500, 150000, 2500, N'Tiền mặt', N'Khách mua dùng gia đình', GETDATE());
    DECLARE @I1 INT = SCOPE_IDENTITY();
    INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice) VALUES
    (@I1, 1, N'Mì Hảo Hảo Tôm chua cay 75g', N'Gói', 5, 3800, 4500, 22500),
    (@I1, 3, N'Nước ngọt Coca Cola 320ml', N'Lon', 3, 8500, 10000, 30000),
    (@I1, 7, N'Dầu ăn Tường An Cooking Oil 1L', N'Chai', 1, 43000, 52000, 52000),
    (@I1, 9, N'Hạt nêm Knorr Thịt thăn 400g', N'Gói', 1, 31000, 38000, 38000),
    (@I1, 21, N'Nước tăng lực Red Bull 250ml', N'Lon', 1, 11500, 14000, 14000);

    -- Hóa đơn 2 (Hôm nay - QR)
    INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
    VALUES (N'HD20261105002', 2, 2, 283000, 10000, 273000, 273000, 0, N'Chuyển khoản QR', N'Khách quen chiết khấu 10k', GETDATE());
    DECLARE @I2 INT = SCOPE_IDENTITY();
    INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice) VALUES
    (@I2, 19, N'Gạo thơm ST25 Ông Cua túi 5kg', N'Túi', 1, 165000, 195000, 195000),
    (@I2, 11, N'Sữa tươi Vinamilk có đường 180ml', N'Lốc (4)', 1, 28000, 34000, 34000),
    (@I2, 6, N'Nước mắm Nam Ngư Đệ Nhị 900ml', N'Chai', 1, 22000, 28000, 28000),
    (@I2, 16, N'Nước rửa chén Sunlight Chanh 750g', N'Chai', 1, 23000, 29000, 29000);

    -- Hóa đơn 3 (1 ngày trước)
    INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
    VALUES (N'HD20261104001', 3, 2, 382000, 0, 382000, 400000, 18000, N'Tiền mặt', N'Cô Ba mua hàng tuần', DATEADD(DAY, -1, GETDATE()));
    DECLARE @I3 INT = SCOPE_IDENTITY();
    INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice) VALUES
    (@I3, 15, N'Bột giặt OMO Matic Cửa trên 3kg', N'Túi', 1, 175000, 210000, 210000),
    (@I3, 17, N'Dầu gội Clear Bạc hà 650g', N'Chai', 1, 155000, 185000, 185000),
    (@I3, 1, N'Mì Hảo Hảo Tôm chua cay 75g', N'Gói', 10, 3800, 4500, 45000);

    -- Hóa đơn 4 (2 ngày trước)
    INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
    VALUES (N'HD20261103001', NULL, 2, 234000, 0, 234000, 250000, 16000, N'Tiền mặt', N'Khách vãng lai', DATEADD(DAY, -2, GETDATE()));
    DECLARE @I4 INT = SCOPE_IDENTITY();
    INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice) VALUES
    (@I4, 23, N'Bia Tiger lon 330ml', N'Lon', 12, 16500, 19500, 234000);

    -- Hóa đơn 5 (3 ngày trước)
    INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
    VALUES (N'HD20261102001', 4, 2, 116000, 0, 116000, 120000, 4000, N'Tiền mặt', N'Bác Năm mua bánh sữa', DATEADD(DAY, -3, GETDATE()));
    DECLARE @I5 INT = SCOPE_IDENTITY();
    INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice) VALUES
    (@I5, 13, N'Bánh Chocopie Orion hộp 12 cái', N'Hộp', 1, 48000, 58000, 58000),
    (@I5, 11, N'Sữa tươi Vinamilk có đường 180ml', N'Lốc (4)', 1, 28000, 34000, 34000),
    (@I5, 20, N'Trứng gà tươi Ba Huân (Hộp 10)', N'Hộp', 1, 27000, 33000, 33000);
END
GO

-- 8. Thêm Phiếu kiểm kê mẫu (Stock Adjustment)
IF NOT EXISTS (SELECT 1 FROM StockAdjustments)
BEGIN
    INSERT INTO StockAdjustments (Code, ProductId, OldQuantity, NewQuantity, ChangeQuantity, Reason, EmployeeId, AdjustedAt)
    VALUES (N'KK001', 20, 6, 4, -2, N'Vỡ 2 quả trong quá trình vận chuyển', 3, DATEADD(DAY, -1, GETDATE()));
END
GO

PRINT N'Cơ sở dữ liệu QuanLiCuaHangTapHoa đã được khởi tạo và nạp dữ liệu mẫu thành công!';
GO
