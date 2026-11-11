using System;
using System.Data.SqlClient;
using System.IO;
using System.Text;

namespace QuanLiCuaHangTapHoa.Seeder
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.OutputEncoding = Encoding.UTF8;
            Console.WriteLine("=== ĐANG KHỞI TẠO VÀ NẠP CSDL TIẾNG VIỆT CHUẨN UNICODE ===");

            string masterConnStr = @"Server=(localdb)\MSSQLLocalDB;Database=master;Integrated Security=True;";
            string dbConnStr = @"Server=(localdb)\MSSQLLocalDB;Database=QuanLiCuaHangTapHoa;Integrated Security=True;";

            // 1. Tạo database nếu chưa có
            using (var conn = new SqlConnection(masterConnStr))
            {
                conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
                        IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'QuanLiCuaHangTapHoa')
                        BEGIN
                            CREATE DATABASE QuanLiCuaHangTapHoa COLLATE Vietnamese_CI_AS;
                        END";
                    cmd.ExecuteNonQuery();
                }
            }
            Console.WriteLine("1. Database QuanLiCuaHangTapHoa sẵn sàng.");

            // 2. Tạo bảng và nạp dữ liệu chuẩn
            using (var conn = new SqlConnection(dbConnStr))
            {
                conn.Open();

                // Drop bảng cũ
                string dropSql = @"
                    IF OBJECT_ID('dbo.StockAdjustments', 'U') IS NOT NULL DROP TABLE dbo.StockAdjustments;
                    IF OBJECT_ID('dbo.InvoiceDetails', 'U') IS NOT NULL DROP TABLE dbo.InvoiceDetails;
                    IF OBJECT_ID('dbo.Invoices', 'U') IS NOT NULL DROP TABLE dbo.Invoices;
                    IF OBJECT_ID('dbo.GoodsReceiptDetails', 'U') IS NOT NULL DROP TABLE dbo.GoodsReceiptDetails;
                    IF OBJECT_ID('dbo.GoodsReceipts', 'U') IS NOT NULL DROP TABLE dbo.GoodsReceipts;
                    IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
                    IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL DROP TABLE dbo.Employees;
                    IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
                    IF OBJECT_ID('dbo.Suppliers', 'U') IS NOT NULL DROP TABLE dbo.Suppliers;
                    IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL DROP TABLE dbo.Categories;";
                using (var cmd = new SqlCommand(dropSql, conn))
                {
                    cmd.ExecuteNonQuery();
                }
                Console.WriteLine("2. Đã dọn dẹp bảng cũ.");

                // Create tables
                string createTablesSql = @"
                    CREATE TABLE Categories (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        Code NVARCHAR(50) NOT NULL UNIQUE,
                        Name NVARCHAR(150) NOT NULL,
                        Description NVARCHAR(500) NULL,
                        CreatedAt DATETIME DEFAULT GETDATE()
                    );

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

                    CREATE TABLE Employees (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        Code NVARCHAR(50) NOT NULL UNIQUE,
                        Name NVARCHAR(150) NOT NULL,
                        Phone NVARCHAR(50) NULL,
                        Role NVARCHAR(50) NOT NULL DEFAULT N'Thu ngân',
                        Status NVARCHAR(50) NOT NULL DEFAULT N'active',
                        CreatedAt DATETIME DEFAULT GETDATE()
                    );

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

                    CREATE TABLE GoodsReceiptDetails (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        ReceiptId INT NOT NULL FOREIGN KEY REFERENCES GoodsReceipts(Id) ON DELETE CASCADE,
                        ProductId INT NOT NULL FOREIGN KEY REFERENCES Products(Id),
                        Quantity INT NOT NULL,
                        CostPrice DECIMAL(18,2) NOT NULL,
                        TotalPrice DECIMAL(18,2) NOT NULL
                    );

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
                    );";

                using (var cmd = new SqlCommand(createTablesSql, conn))
                {
                    cmd.ExecuteNonQuery();
                }
                Console.WriteLine("3. Đã tạo mới toàn bộ cấu trúc 10 bảng.");

                // INSERT CATEGORIES (Parameterized)
                string[,] categories = new string[,] {
                    { "LSP01", "Đồ uống & Nước giải khát", "Nước ngọt, nước suối, bia, nước tăng lực" },
                    { "LSP02", "Mì & Thực phẩm ăn liền", "Mì gói, phở, bún miến, cháo ăn liền, xúc xích" },
                    { "LSP03", "Gia vị & Nước chấm", "Nước mắm, dầu ăn, hạt nêm, bột ngọt, tương ớt" },
                    { "LSP04", "Sữa & Chế phẩm sữa", "Sữa tươi, sữa đặc, sữa chua, phô mai" },
                    { "LSP05", "Bánh kẹo & Snack", "Bánh quy, kẹo, bim bim, bánh ngọt" },
                    { "LSP06", "Hóa phẩm & Tẩy rửa", "Bột giặt, nước rửa chén, nước xả, lau sàn" },
                    { "LSP07", "Chăm sóc cá nhân", "Dầu gội, sữa tắm, kem đánh răng, xà phòng" },
                    { "LSP08", "Gạo & Đồ khô", "Gạo sạch, đường cát, các loại đậu, trứng gà vịt" }
                };

                for (int i = 0; i < categories.GetLength(0); i++)
                {
                    using (var cmd = new SqlCommand("INSERT INTO Categories (Code, Name, Description) VALUES (@Code, @Name, @Desc);", conn))
                    {
                        cmd.Parameters.AddWithValue("@Code", categories[i, 0]);
                        cmd.Parameters.AddWithValue("@Name", categories[i, 1]);
                        cmd.Parameters.AddWithValue("@Desc", categories[i, 2]);
                        cmd.ExecuteNonQuery();
                    }
                }
                Console.WriteLine("4. Đã nạp 8 loại sản phẩm chuẩn tiếng Việt.");

                // INSERT SUPPLIERS (Parameterized)
                string[,] suppliers = new string[,] {
                    { "NCC01", "Công ty CP Acecook Việt Nam", "02838154064", "lienhe@acecookvietnam.com", "KCN Tân Bình, Tây Thạnh, Tân Phú, TP.HCM", "NCC mì tôm chính hãng" },
                    { "NCC02", "Công ty TNHH Suntory PepsiCo VN", "02838219468", "sales@suntorypepsico.vn", "Tầng 5 Sheraton Saigon, Q.1, TP.HCM", "NCC nước ngọt, Sting, Aquafina" },
                    { "NCC03", "Công ty CP Sữa Việt Nam (Vinamilk)", "1900636979", "vinamilk@vinamilk.com.vn", "Số 10 Tân Trào, Tân Phú, Q.7, TP.HCM", "NCC sữa chua, sữa tươi" },
                    { "NCC04", "Công ty TNHH Unilever Việt Nam", "02854135686", "unilever@unilever.com.vn", "156 Nguyễn Lương Bằng, Q.7, TP.HCM", "NCC OMO, Sunlight, Clear, P/S" },
                    { "NCC05", "Công ty CP Hàng tiêu dùng Masan", "02862563862", "contact@masangroup.com", "Mplaza Saigon, Lê Duẩn, Q.1, TP.HCM", "NCC Chinsu, Nam Ngư, Omachi" },
                    { "NCC06", "Đại lý Gạo Sạch Miền Tây", "0908123456", "gaomientay@gmail.com", "128 Quốc Lộ 1A, Tiền Giang", "NCC gạo ST25, gạo thơm lài" }
                };

                for (int i = 0; i < suppliers.GetLength(0); i++)
                {
                    using (var cmd = new SqlCommand("INSERT INTO Suppliers (Code, Name, Phone, Email, Address, Notes) VALUES (@Code, @Name, @Phone, @Email, @Addr, @Notes);", conn))
                    {
                        cmd.Parameters.AddWithValue("@Code", suppliers[i, 0]);
                        cmd.Parameters.AddWithValue("@Name", suppliers[i, 1]);
                        cmd.Parameters.AddWithValue("@Phone", suppliers[i, 2]);
                        cmd.Parameters.AddWithValue("@Email", suppliers[i, 3]);
                        cmd.Parameters.AddWithValue("@Addr", suppliers[i, 4]);
                        cmd.Parameters.AddWithValue("@Notes", suppliers[i, 5]);
                        cmd.ExecuteNonQuery();
                    }
                }
                Console.WriteLine("5. Đã nạp 6 nhà cung cấp chuẩn tiếng Việt.");

                // INSERT EMPLOYEES
                string[,] employees = new string[,] {
                    { "NV01", "Nguyễn Văn Quản", "0912345678", "Quản lý", "active" },
                    { "NV02", "Trần Thị Mai", "0987654321", "Thu ngân", "active" },
                    { "NV03", "Lê Hoàng Nam", "0903112233", "Nhân viên kho", "active" }
                };
                for (int i = 0; i < employees.GetLength(0); i++)
                {
                    using (var cmd = new SqlCommand("INSERT INTO Employees (Code, Name, Phone, Role, Status) VALUES (@Code, @Name, @Phone, @Role, @Status);", conn))
                    {
                        cmd.Parameters.AddWithValue("@Code", employees[i, 0]);
                        cmd.Parameters.AddWithValue("@Name", employees[i, 1]);
                        cmd.Parameters.AddWithValue("@Phone", employees[i, 2]);
                        cmd.Parameters.AddWithValue("@Role", employees[i, 3]);
                        cmd.Parameters.AddWithValue("@Status", employees[i, 4]);
                        cmd.ExecuteNonQuery();
                    }
                }
                Console.WriteLine("6. Đã nạp 3 nhân viên.");

                // INSERT CUSTOMERS
                object[,] customers = new object[,] {
                    { "KH01", "Chị Nguyễn Thị Lan", "0909111222", "Số 12 Đường Số 5, P.7, Gò Vấp", 125, 1250000m },
                    { "KH02", "Anh Trần Minh Tuấn", "0918222333", "Số 45 Lê Lợi, P. Bến Nghé, Q.1", 85, 850000m },
                    { "KH03", "Cô Ba Hạnh", "0933444555", "Hẻm 88 Nguyễn Trãi, P.3, Q.5", 210, 2100000m },
                    { "KH04", "Bác Hoàng Năm", "0977888999", "Số 15 Hoàng Hoa Thám, Bình Thạnh", 45, 450000m }
                };
                for (int i = 0; i < customers.GetLength(0); i++)
                {
                    using (var cmd = new SqlCommand("INSERT INTO Customers (Code, Name, Phone, Address, Points, TotalSpent) VALUES (@Code, @Name, @Phone, @Addr, @Pts, @Spent);", conn))
                    {
                        cmd.Parameters.AddWithValue("@Code", customers[i, 0]);
                        cmd.Parameters.AddWithValue("@Name", customers[i, 1]);
                        cmd.Parameters.AddWithValue("@Phone", customers[i, 2]);
                        cmd.Parameters.AddWithValue("@Addr", customers[i, 3]);
                        cmd.Parameters.AddWithValue("@Pts", customers[i, 4]);
                        cmd.Parameters.AddWithValue("@Spent", customers[i, 5]);
                        cmd.ExecuteNonQuery();
                    }
                }
                Console.WriteLine("7. Đã nạp 4 khách hàng.");

                // INSERT 23 PRODUCTS
                object[,] products = new object[,] {
                    { "SP001", "8934563138164", "Mì Hảo Hảo Tôm chua cay 75g", 2, 1, "Gói", 3800m, 4500m, 150, 20, "🍜" },
                    { "SP002", "8936079121785", "Mì Omachi Sườn hầm ngũ quả 80g", 2, 5, "Gói", 7500m, 9000m, 85, 15, "🍜" },
                    { "SP003", "8935049500544", "Nước ngọt Coca Cola 320ml", 1, 2, "Lon", 8500m, 10000m, 48, 12, "🥤" },
                    { "SP004", "8934588012111", "Nước ngọt Pepsi lon 320ml", 1, 2, "Lon", 8200m, 10000m, 42, 12, "🥤" },
                    { "SP005", "8934588012222", "Nước khoáng Aquafina 500ml", 1, 2, "Chai", 4000m, 5500m, 60, 15, "💧" },
                    { "SP006", "8934561240012", "Nước mắm Nam Ngư Đệ Nhị 900ml", 3, 5, "Chai", 22000m, 28000m, 24, 6, "🏺" },
                    { "SP007", "8934673129871", "Dầu ăn Tường An Cooking Oil 1L", 3, 5, "Chai", 43000m, 52000m, 18, 5, "🛢️" },
                    { "SP008", "8936079120021", "Nước tương Chinsu Nấm Shiitake 330ml", 3, 5, "Chai", 18000m, 23000m, 20, 5, "🏺" },
                    { "SP009", "8934673554412", "Hạt nêm Knorr Thịt thăn 400g", 3, 4, "Gói", 31000m, 38000m, 16, 5, "🧂" },
                    { "SP010", "8934673667789", "Bột ngọt Ajinomoto 454g", 3, 5, "Gói", 32000m, 39000m, 15, 5, "🧂" },
                    { "SP011", "8934673889911", "Sữa tươi Vinamilk có đường 180ml", 4, 3, "Lốc (4)", 28000m, 34000m, 35, 8, "🥛" },
                    { "SP012", "8934673998822", "Sữa chua Vinamilk có đường 100g", 4, 3, "Lốc (4)", 24000m, 29000m, 22, 6, "🍨" },
                    { "SP013", "8936036010014", "Bánh Chocopie Orion hộp 12 cái", 5, 1, "Hộp", 48000m, 58000m, 12, 4, "🥧" },
                    { "SP014", "8936036020025", "Snack Oishi Tôm cay 40g", 5, 1, "Gói", 5000m, 6500m, 45, 10, "🍿" },
                    { "SP015", "8934868112233", "Bột giặt OMO Matic Cửa trên 3kg", 6, 4, "Túi", 175000m, 210000m, 8, 3, "🧺" },
                    { "SP016", "8934868223344", "Nước rửa chén Sunlight Chanh 750g", 6, 4, "Chai", 23000m, 29000m, 19, 5, "🧴" },
                    { "SP017", "8934868334455", "Dầu gội Clear Bạc hà 650g", 7, 4, "Chai", 155000m, 185000m, 9, 3, "🧴" },
                    { "SP018", "8934868445566", "Kem đánh răng P/S Bảo vệ 123 200g", 7, 4, "Hộp", 26000m, 33000m, 25, 6, "🪥" },
                    { "SP019", "8938501234567", "Gạo thơm ST25 Ông Cua túi 5kg", 8, 6, "Túi", 165000m, 195000m, 14, 5, "🌾" },
                    { "SP020", "8938502345678", "Trứng gà tươi Ba Huân (Hộp 10)", 8, 6, "Hộp", 27000m, 33000m, 4, 10, "🥚" },
                    { "SP021", "8934588019999", "Nước tăng lực Red Bull 250ml", 1, 2, "Lon", 11500m, 14000m, 3, 15, "⚡" },
                    { "SP022", "8936079128888", "Xúc xích tiệt trùng Vissan 4 cây", 2, 5, "Gói", 16000m, 20000m, 5, 10, "🌭" },
                    { "SP023", "8934588033333", "Bia Tiger lon 330ml", 1, 2, "Lon", 16500m, 19500m, 72, 24, "🍺" }
                };

                for (int i = 0; i < products.GetLength(0); i++)
                {
                    using (var cmd = new SqlCommand(@"
                        INSERT INTO Products (Code, Barcode, Name, CategoryId, SupplierId, Unit, CostPrice, SellingPrice, StockQuantity, MinStockAlert, ImageIcon)
                        VALUES (@Code, @Barcode, @Name, @CatId, @SupId, @Unit, @Cost, @Sell, @Stock, @Alert, @Icon);", conn))
                    {
                        cmd.Parameters.AddWithValue("@Code", products[i, 0]);
                        cmd.Parameters.AddWithValue("@Barcode", products[i, 1]);
                        cmd.Parameters.AddWithValue("@Name", products[i, 2]);
                        cmd.Parameters.AddWithValue("@CatId", products[i, 3]);
                        cmd.Parameters.AddWithValue("@SupId", products[i, 4]);
                        cmd.Parameters.AddWithValue("@Unit", products[i, 5]);
                        cmd.Parameters.AddWithValue("@Cost", products[i, 6]);
                        cmd.Parameters.AddWithValue("@Sell", products[i, 7]);
                        cmd.Parameters.AddWithValue("@Stock", products[i, 8]);
                        cmd.Parameters.AddWithValue("@Alert", products[i, 9]);
                        cmd.Parameters.AddWithValue("@Icon", products[i, 10]);
                        cmd.ExecuteNonQuery();
                    }
                }
                Console.WriteLine("8. Đã nạp 23 sản phẩm với đầy đủ Tên Tiếng Việt & Emoji Icon.");

                // INSERT SAMPLE RECEIPTS
                using (var cmd = new SqlCommand(@"
                    INSERT INTO GoodsReceipts (Code, SupplierId, EmployeeId, TotalAmount, Notes, ReceiptDate)
                    VALUES (N'PN20261103001', 1, 3, 570000, N'Nhập mì tôm và bánh kẹo', DATEADD(DAY, -2, GETDATE()));
                    SELECT SCOPE_IDENTITY();", conn))
                {
                    int r1 = Convert.ToInt32(cmd.ExecuteScalar());
                    using (var dCmd = new SqlCommand("INSERT INTO GoodsReceiptDetails (ReceiptId, ProductId, Quantity, CostPrice, TotalPrice) VALUES (@R, 1, 100, 3800, 380000), (@R, 14, 38, 5000, 190000);", conn))
                    {
                        dCmd.Parameters.AddWithValue("@R", r1);
                        dCmd.ExecuteNonQuery();
                    }
                }

                using (var cmd = new SqlCommand(@"
                    INSERT INTO GoodsReceipts (Code, SupplierId, EmployeeId, TotalAmount, Notes, ReceiptDate)
                    VALUES (N'PN20261104001', 2, 3, 1269000, N'Nhập nước giải khát Pepsi, Aquafina, Tiger', DATEADD(DAY, -1, GETDATE()));
                    SELECT SCOPE_IDENTITY();", conn))
                {
                    int r2 = Convert.ToInt32(cmd.ExecuteScalar());
                    using (var dCmd = new SqlCommand("INSERT INTO GoodsReceiptDetails (ReceiptId, ProductId, Quantity, CostPrice, TotalPrice) VALUES (@R, 3, 48, 8500, 408000), (@R, 5, 50, 4000, 200000), (@R, 23, 40, 16500, 661000);", conn))
                    {
                        dCmd.Parameters.AddWithValue("@R", r2);
                        dCmd.ExecuteNonQuery();
                    }
                }
                Console.WriteLine("9. Đã nạp 2 phiếu nhập hàng mẫu.");

                // INSERT SAMPLE INVOICES
                using (var cmd = new SqlCommand(@"
                    INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
                    VALUES (N'HD20261105001', 1, 2, 147500, 0, 147500, 150000, 2500, N'Tiền mặt', N'Khách mua dùng gia đình', GETDATE());
                    SELECT SCOPE_IDENTITY();", conn))
                {
                    int i1 = Convert.ToInt32(cmd.ExecuteScalar());
                    using (var dCmd = new SqlCommand(@"
                        INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice) VALUES
                        (@I, 1, N'Mì Hảo Hảo Tôm chua cay 75g', N'Gói', 5, 3800, 4500, 22500),
                        (@I, 3, N'Nước ngọt Coca Cola 320ml', N'Lon', 3, 8500, 10000, 30000),
                        (@I, 7, N'Dầu ăn Tường An Cooking Oil 1L', N'Chai', 1, 43000, 52000, 52000),
                        (@I, 9, N'Hạt nêm Knorr Thịt thăn 400g', N'Gói', 1, 31000, 38000, 38000),
                        (@I, 21, N'Nước tăng lực Red Bull 250ml', N'Lon', 1, 11500, 14000, 14000);", conn))
                    {
                        dCmd.Parameters.AddWithValue("@I", i1);
                        dCmd.ExecuteNonQuery();
                    }
                }

                using (var cmd = new SqlCommand(@"
                    INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
                    VALUES (N'HD20261105002', 2, 2, 283000, 10000, 273000, 273000, 0, N'Chuyển khoản QR', N'Khách quen chiết khấu 10k', GETDATE());
                    SELECT SCOPE_IDENTITY();", conn))
                {
                    int i2 = Convert.ToInt32(cmd.ExecuteScalar());
                    using (var dCmd = new SqlCommand(@"
                        INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice) VALUES
                        (@I, 19, N'Gạo thơm ST25 Ông Cua túi 5kg', N'Túi', 1, 165000, 195000, 195000),
                        (@I, 11, N'Sữa tươi Vinamilk có đường 180ml', N'Lốc (4)', 1, 28000, 34000, 34000),
                        (@I, 6, N'Nước mắm Nam Ngư Đệ Nhị 900ml', N'Chai', 1, 22000, 28000, 28000),
                        (@I, 16, N'Nước rửa chén Sunlight Chanh 750g', N'Chai', 1, 23000, 29000, 29000);", conn))
                    {
                        dCmd.Parameters.AddWithValue("@I", i2);
                        dCmd.ExecuteNonQuery();
                    }
                }

                using (var cmd = new SqlCommand(@"
                    INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
                    VALUES (N'HD20261104001', 3, 2, 382000, 0, 382000, 400000, 18000, N'Tiền mặt', N'Cô Ba mua hàng tuần', DATEADD(DAY, -1, GETDATE()));
                    SELECT SCOPE_IDENTITY();", conn))
                {
                    int i3 = Convert.ToInt32(cmd.ExecuteScalar());
                    using (var dCmd = new SqlCommand(@"
                        INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice) VALUES
                        (@I, 15, N'Bột giặt OMO Matic Cửa trên 3kg', N'Túi', 1, 175000, 210000, 210000),
                        (@I, 17, N'Dầu gội Clear Bạc hà 650g', N'Chai', 1, 155000, 185000, 185000),
                        (@I, 1, N'Mì Hảo Hảo Tôm chua cay 75g', N'Gói', 10, 3800, 4500, 45000);", conn))
                    {
                        dCmd.Parameters.AddWithValue("@I", i3);
                        dCmd.ExecuteNonQuery();
                    }
                }

                using (var cmd = new SqlCommand(@"
                    INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
                    VALUES (N'HD20261103001', NULL, 2, 234000, 0, 234000, 250000, 16000, N'Tiền mặt', N'Khách vãng lai', DATEADD(DAY, -2, GETDATE()));
                    SELECT SCOPE_IDENTITY();", conn))
                {
                    int i4 = Convert.ToInt32(cmd.ExecuteScalar());
                    using (var dCmd = new SqlCommand("INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice) VALUES (@I, 23, N'Bia Tiger lon 330ml', N'Lon', 12, 16500, 19500, 234000);", conn))
                    {
                        dCmd.Parameters.AddWithValue("@I", i4);
                        dCmd.ExecuteNonQuery();
                    }
                }

                using (var cmd = new SqlCommand(@"
                    INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
                    VALUES (N'HD20261102001', 4, 2, 116000, 0, 116000, 120000, 4000, N'Tiền mặt', N'Bác Năm mua bánh sữa', DATEADD(DAY, -3, GETDATE()));
                    SELECT SCOPE_IDENTITY();", conn))
                {
                    int i5 = Convert.ToInt32(cmd.ExecuteScalar());
                    using (var dCmd = new SqlCommand(@"
                        INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice) VALUES
                        (@I, 13, N'Bánh Chocopie Orion hộp 12 cái', N'Hộp', 1, 48000, 58000, 58000),
                        (@I, 11, N'Sữa tươi Vinamilk có đường 180ml', N'Lốc (4)', 1, 28000, 34000, 34000),
                        (@I, 20, N'Trứng gà tươi Ba Huân (Hộp 10)', N'Hộp', 1, 27000, 33000, 33000);", conn))
                    {
                        dCmd.Parameters.AddWithValue("@I", i5);
                        dCmd.ExecuteNonQuery();
                    }
                }
                Console.WriteLine("10. Đã nạp 5 hóa đơn bán hàng mẫu.");

                // INSERT STOCK ADJUSTMENT
                using (var cmd = new SqlCommand(@"
                    INSERT INTO StockAdjustments (Code, ProductId, OldQuantity, NewQuantity, ChangeQuantity, Reason, EmployeeId, AdjustedAt)
                    VALUES (N'KK001', 20, 6, 4, -2, N'Vỡ 2 quả trong quá trình vận chuyển', 3, DATEADD(DAY, -1, GETDATE()));", conn))
                {
                    cmd.ExecuteNonQuery();
                }
                Console.WriteLine("11. Đã nạp phiếu kiểm kê kho mẫu.");
            }

            Console.WriteLine("=== THÀNH CÔNG: CƠ SỞ DỮ LIỆU ĐÃ NẠP XONG 100% TIẾNG VIỆT CHUẨN UNICODE ===");
        }
    }
}
