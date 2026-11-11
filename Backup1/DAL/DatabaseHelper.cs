using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using QuanLiCuaHangTapHoa.Models;

namespace QuanLiCuaHangTapHoa.DAL
{
    public static class DatabaseHelper
    {
        public static string ConnectionString
        {
            get
            {
                var connSetting = ConfigurationManager.ConnectionStrings["DefaultConnection"];
                string connStr = connSetting != null ? connSetting.ConnectionString : null;
                if (string.IsNullOrEmpty(connStr))
                {
                    connStr = @"Server=(localdb)\MSSQLLocalDB;Database=QuanLiCuaHangTapHoa;Integrated Security=True;MultipleActiveResultSets=True;";
                }
                return connStr;
            }
        }

        public static SqlConnection GetConnection()
        {
            var conn = new SqlConnection(ConnectionString);
            if (conn.State != ConnectionState.Open)
            {
                conn.Open();
            }
            return conn;
        }

        public static DataTable ExecuteQuery(string sql, params SqlParameter[] parameters)
        {
            using (var conn = GetConnection())
            using (var cmd = new SqlCommand(sql, conn))
            {
                if (parameters != null && parameters.Length > 0)
                {
                    cmd.Parameters.AddRange(parameters);
                }
                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }

        public static int ExecuteNonQuery(string sql, params SqlParameter[] parameters)
        {
            using (var conn = GetConnection())
            using (var cmd = new SqlCommand(sql, conn))
            {
                if (parameters != null && parameters.Length > 0)
                {
                    cmd.Parameters.AddRange(parameters);
                }
                return cmd.ExecuteNonQuery();
            }
        }

        public static object ExecuteScalar(string sql, params SqlParameter[] parameters)
        {
            using (var conn = GetConnection())
            using (var cmd = new SqlCommand(sql, conn))
            {
                if (parameters != null && parameters.Length > 0)
                {
                    cmd.Parameters.AddRange(parameters);
                }
                return cmd.ExecuteScalar();
            }
        }

        // ==================== DASHBOARD ====================
        public static DataRow GetDashboardSummary()
        {
            string sql = @"
                SELECT 
                    (SELECT ISNULL(SUM(TotalAmount), 0) FROM Invoices WHERE CAST(InvoiceDate AS DATE) = CAST(GETDATE() AS DATE)) AS TodayRevenue,
                    (SELECT COUNT(*) FROM Invoices WHERE CAST(InvoiceDate AS DATE) = CAST(GETDATE() AS DATE)) AS TodayOrders,
                    (SELECT ISNULL(SUM(TotalAmount), 0) FROM Invoices WHERE YEAR(InvoiceDate) = YEAR(GETDATE()) AND MONTH(InvoiceDate) = MONTH(GETDATE())) AS MonthRevenue,
                    (SELECT COUNT(*) FROM Invoices) AS TotalOrders,
                    (SELECT COUNT(*) FROM Customers) AS TotalCustomers,
                    (SELECT ISNULL(SUM(Quantity), 0) FROM InvoiceDetails) AS SoldCount,
                    (SELECT ISNULL(SUM(d.Quantity), 0) FROM InvoiceDetails d JOIN Invoices i ON d.InvoiceId = i.Id WHERE CAST(i.InvoiceDate AS DATE) = CAST(GETDATE() AS DATE)) AS SoldToday,
                    (SELECT ISNULL(SUM(StockQuantity * CostPrice), 0) FROM Products) AS InventoryValue,
                    (SELECT ISNULL(SUM(StockQuantity), 0) FROM Products) AS InventoryTotalUnits,
                    (SELECT COUNT(*) FROM Products WHERE StockQuantity <= MinStockAlert) AS LowStockCount,
                    (SELECT ISNULL(SUM(TotalPrice - (Quantity * CostPrice)), 0) FROM InvoiceDetails) AS GrossProfit;
            ";
            DataTable dt = ExecuteQuery(sql);
            return dt.Rows.Count > 0 ? dt.Rows[0] : null;
        }

        public static DataTable GetTopSellingProducts(int top)
        {
            string sql = string.Format(@"
                SELECT TOP ({0})
                    d.ProductId, d.ProductName, d.Unit, 
                    SUM(d.Quantity) AS TotalSold, 
                    SUM(d.TotalPrice) AS TotalRevenue
                FROM InvoiceDetails d
                GROUP BY d.ProductId, d.ProductName, d.Unit
                ORDER BY TotalSold DESC;
            ", top);
            return ExecuteQuery(sql);
        }

        public static DataTable GetRevenueLast7Days()
        {
            string sql = @"
                WITH Dates AS (
                    SELECT CAST(DATEADD(DAY, -6, GETDATE()) AS DATE) AS [Date]
                    UNION ALL
                    SELECT DATEADD(DAY, 1, [Date])
                    FROM Dates
                    WHERE [Date] < CAST(GETDATE() AS DATE)
                )
                SELECT 
                    d.[Date],
                    CONVERT(VARCHAR(5), d.[Date], 103) AS Label,
                    ISNULL(SUM(i.TotalAmount), 0) AS Revenue,
                    COUNT(i.Id) AS Orders
                FROM Dates d
                LEFT JOIN Invoices i ON CAST(i.InvoiceDate AS DATE) = d.[Date]
                GROUP BY d.[Date]
                ORDER BY d.[Date] ASC;
            ";
            return ExecuteQuery(sql);
        }

        public static DataTable GetRecentInvoices(int limit)
        {
            string sql = string.Format(@"
                SELECT TOP ({0})
                    i.Id, i.Code, i.TotalAmount, i.PaymentMethod, i.InvoiceDate,
                    ISNULL(c.Name, N'Khách lẻ') AS CustomerName,
                    ISNULL(e.Name, N'Thu ngân') AS EmployeeName
                FROM Invoices i
                LEFT JOIN Customers c ON i.CustomerId = c.Id
                LEFT JOIN Employees e ON i.EmployeeId = e.Id
                ORDER BY i.Id DESC;
            ", limit);
            return ExecuteQuery(sql);
        }

        // ==================== CATEGORIES ====================
        public static List<Category> GetCategories()
        {
            string sql = @"
                SELECT c.Id, c.Code, c.Name, c.Description, c.CreatedAt,
                       COUNT(p.Id) AS ProductCount
                FROM Categories c
                LEFT JOIN Products p ON c.Id = p.CategoryId
                GROUP BY c.Id, c.Code, c.Name, c.Description, c.CreatedAt
                ORDER BY c.Id ASC;
            ";
            DataTable dt = ExecuteQuery(sql);
            var list = new List<Category>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new Category
                {
                    Id = Convert.ToInt32(row["Id"]),
                    Code = row["Code"].ToString(),
                    Name = row["Name"].ToString(),
                    Description = row["Description"] != DBNull.Value ? row["Description"].ToString() : null,
                    CreatedAt = Convert.ToDateTime(row["CreatedAt"]),
                    ProductCount = Convert.ToInt32(row["ProductCount"])
                });
            }
            return list;
        }

        public static int AddCategory(string code, string name, string description)
        {
            string sql = @"INSERT INTO Categories (Code, Name, Description) VALUES (@Code, @Name, @Desc);";
            return ExecuteNonQuery(sql,
                new SqlParameter("@Code", code),
                new SqlParameter("@Name", name),
                new SqlParameter("@Desc", (object)description ?? DBNull.Value));
        }

        public static int UpdateCategory(int id, string name, string description)
        {
            string sql = @"UPDATE Categories SET Name = @Name, Description = @Desc WHERE Id = @Id;";
            return ExecuteNonQuery(sql,
                new SqlParameter("@Id", id),
                new SqlParameter("@Name", name),
                new SqlParameter("@Desc", (object)description ?? DBNull.Value));
        }

        public static bool DeleteCategory(int id, out string error)
        {
            error = null;
            object countObj = ExecuteScalar("SELECT COUNT(*) FROM Products WHERE CategoryId = @Id", new SqlParameter("@Id", id));
            int count = Convert.ToInt32(countObj);
            if (count > 0)
            {
                error = string.Format("Không thể xóa vì còn {0} sản phẩm thuộc loại này!", count);
                return false;
            }
            ExecuteNonQuery("DELETE FROM Categories WHERE Id = @Id", new SqlParameter("@Id", id));
            return true;
        }

        // ==================== SUPPLIERS ====================
        public static List<Supplier> GetSuppliers()
        {
            string sql = "SELECT * FROM Suppliers ORDER BY Id DESC;";
            DataTable dt = ExecuteQuery(sql);
            var list = new List<Supplier>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new Supplier
                {
                    Id = Convert.ToInt32(row["Id"]),
                    Code = row["Code"].ToString(),
                    Name = row["Name"].ToString(),
                    Phone = row["Phone"] != DBNull.Value ? row["Phone"].ToString() : null,
                    Email = row["Email"] != DBNull.Value ? row["Email"].ToString() : null,
                    Address = row["Address"] != DBNull.Value ? row["Address"].ToString() : null,
                    Notes = row["Notes"] != DBNull.Value ? row["Notes"].ToString() : null,
                    CreatedAt = Convert.ToDateTime(row["CreatedAt"])
                });
            }
            return list;
        }

        public static int AddSupplier(string code, string name, string phone, string email, string address, string notes)
        {
            string sql = @"INSERT INTO Suppliers (Code, Name, Phone, Email, Address, Notes) VALUES (@Code, @Name, @Phone, @Email, @Address, @Notes);";
            return ExecuteNonQuery(sql,
                new SqlParameter("@Code", code),
                new SqlParameter("@Name", name),
                new SqlParameter("@Phone", (object)phone ?? DBNull.Value),
                new SqlParameter("@Email", (object)email ?? DBNull.Value),
                new SqlParameter("@Address", (object)address ?? DBNull.Value),
                new SqlParameter("@Notes", (object)notes ?? DBNull.Value));
        }

        public static int UpdateSupplier(int id, string name, string phone, string email, string address, string notes)
        {
            string sql = @"UPDATE Suppliers SET Name = @Name, Phone = @Phone, Email = @Email, Address = @Address, Notes = @Notes WHERE Id = @Id;";
            return ExecuteNonQuery(sql,
                new SqlParameter("@Id", id),
                new SqlParameter("@Name", name),
                new SqlParameter("@Phone", (object)phone ?? DBNull.Value),
                new SqlParameter("@Email", (object)email ?? DBNull.Value),
                new SqlParameter("@Address", (object)address ?? DBNull.Value),
                new SqlParameter("@Notes", (object)notes ?? DBNull.Value));
        }

        public static int DeleteSupplier(int id)
        {
            return ExecuteNonQuery("DELETE FROM Suppliers WHERE Id = @Id;", new SqlParameter("@Id", id));
        }

        // ==================== CUSTOMERS ====================
        public static List<Customer> GetCustomers(string query)
        {
            string sql = "SELECT * FROM Customers WHERE 1=1";
            var parameters = new List<SqlParameter>();
            if (!string.IsNullOrEmpty(query))
            {
                sql += " AND (Name LIKE @Q OR Phone LIKE @Q OR Code LIKE @Q)";
                parameters.Add(new SqlParameter("@Q", "%" + query.Trim() + "%"));
            }
            sql += " ORDER BY Id DESC;";
            DataTable dt = ExecuteQuery(sql, parameters.ToArray());
            var list = new List<Customer>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new Customer
                {
                    Id = Convert.ToInt32(row["Id"]),
                    Code = row["Code"].ToString(),
                    Name = row["Name"].ToString(),
                    Phone = row["Phone"] != DBNull.Value ? row["Phone"].ToString() : null,
                    Address = row["Address"] != DBNull.Value ? row["Address"].ToString() : null,
                    Points = Convert.ToInt32(row["Points"]),
                    TotalSpent = Convert.ToDecimal(row["TotalSpent"]),
                    CreatedAt = Convert.ToDateTime(row["CreatedAt"])
                });
            }
            return list;
        }

        public static List<Customer> GetCustomers()
        {
            return GetCustomers(null);
        }

        public static int AddCustomer(string code, string name, string phone, string address)
        {
            string sql = @"INSERT INTO Customers (Code, Name, Phone, Address, Points, TotalSpent) VALUES (@Code, @Name, @Phone, @Address, 0, 0);";
            return ExecuteNonQuery(sql,
                new SqlParameter("@Code", code),
                new SqlParameter("@Name", name),
                new SqlParameter("@Phone", (object)phone ?? DBNull.Value),
                new SqlParameter("@Address", (object)address ?? DBNull.Value));
        }

        public static int UpdateCustomer(int id, string name, string phone, string address)
        {
            string sql = @"UPDATE Customers SET Name = @Name, Phone = @Phone, Address = @Address WHERE Id = @Id;";
            return ExecuteNonQuery(sql,
                new SqlParameter("@Id", id),
                new SqlParameter("@Name", name),
                new SqlParameter("@Phone", (object)phone ?? DBNull.Value),
                new SqlParameter("@Address", (object)address ?? DBNull.Value));
        }

        public static int DeleteCustomer(int id)
        {
            return ExecuteNonQuery("DELETE FROM Customers WHERE Id = @Id;", new SqlParameter("@Id", id));
        }

        // ==================== EMPLOYEES ====================
        public static List<Employee> GetEmployees()
        {
            string sql = "SELECT * FROM Employees ORDER BY Id DESC;";
            DataTable dt = ExecuteQuery(sql);
            var list = new List<Employee>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new Employee
                {
                    Id = Convert.ToInt32(row["Id"]),
                    Code = row["Code"].ToString(),
                    Name = row["Name"].ToString(),
                    Phone = row["Phone"] != DBNull.Value ? row["Phone"].ToString() : null,
                    Role = row["Role"].ToString(),
                    Status = row["Status"].ToString(),
                    CreatedAt = Convert.ToDateTime(row["CreatedAt"])
                });
            }
            return list;
        }

        public static int AddEmployee(string code, string name, string phone, string role, string status)
        {
            string sql = @"INSERT INTO Employees (Code, Name, Phone, Role, Status) VALUES (@Code, @Name, @Phone, @Role, @Status);";
            return ExecuteNonQuery(sql,
                new SqlParameter("@Code", code),
                new SqlParameter("@Name", name),
                new SqlParameter("@Phone", (object)phone ?? DBNull.Value),
                new SqlParameter("@Role", role ?? "Thu ngân"),
                new SqlParameter("@Status", status ?? "active"));
        }

        public static int UpdateEmployee(int id, string name, string phone, string role, string status)
        {
            string sql = @"UPDATE Employees SET Name = @Name, Phone = @Phone, Role = @Role, Status = @Status WHERE Id = @Id;";
            return ExecuteNonQuery(sql,
                new SqlParameter("@Id", id),
                new SqlParameter("@Name", name),
                new SqlParameter("@Phone", (object)phone ?? DBNull.Value),
                new SqlParameter("@Role", role ?? "Thu ngân"),
                new SqlParameter("@Status", status ?? "active"));
        }

        public static int DeleteEmployee(int id)
        {
            return ExecuteNonQuery("DELETE FROM Employees WHERE Id = @Id;", new SqlParameter("@Id", id));
        }

        // ==================== PRODUCTS ====================
        public static List<Product> GetProducts(string query, int? categoryId, bool lowStockOnly)
        {
            string sql = @"
                SELECT p.*, c.Name AS CategoryName, s.Name AS SupplierName
                FROM Products p
                LEFT JOIN Categories c ON p.CategoryId = c.Id
                LEFT JOIN Suppliers s ON p.SupplierId = s.Id
                WHERE 1=1
            ";
            var parameters = new List<SqlParameter>();
            if (!string.IsNullOrEmpty(query))
            {
                sql += " AND (p.Name LIKE @Q OR p.Code LIKE @Q OR p.Barcode LIKE @Q)";
                parameters.Add(new SqlParameter("@Q", "%" + query.Trim() + "%"));
            }
            if (categoryId.HasValue && categoryId.Value > 0)
            {
                sql += " AND p.CategoryId = @CatId";
                parameters.Add(new SqlParameter("@CatId", categoryId.Value));
            }
            if (lowStockOnly)
            {
                sql += " AND p.StockQuantity <= p.MinStockAlert";
            }
            sql += " ORDER BY p.Id DESC;";

            DataTable dt = ExecuteQuery(sql, parameters.ToArray());
            var list = new List<Product>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new Product
                {
                    Id = Convert.ToInt32(row["Id"]),
                    Code = row["Code"].ToString(),
                    Barcode = row["Barcode"] != DBNull.Value ? row["Barcode"].ToString() : null,
                    Name = row["Name"].ToString(),
                    CategoryId = row["CategoryId"] != DBNull.Value ? (int?)Convert.ToInt32(row["CategoryId"]) : null,
                    CategoryName = row["CategoryName"] != DBNull.Value ? row["CategoryName"].ToString() : null,
                    SupplierId = row["SupplierId"] != DBNull.Value ? (int?)Convert.ToInt32(row["SupplierId"]) : null,
                    SupplierName = row["SupplierName"] != DBNull.Value ? row["SupplierName"].ToString() : null,
                    Unit = row["Unit"].ToString(),
                    CostPrice = Convert.ToDecimal(row["CostPrice"]),
                    SellingPrice = Convert.ToDecimal(row["SellingPrice"]),
                    StockQuantity = Convert.ToInt32(row["StockQuantity"]),
                    MinStockAlert = Convert.ToInt32(row["MinStockAlert"]),
                    ImageIcon = row["ImageIcon"] != DBNull.Value ? row["ImageIcon"].ToString() : "📦",
                    CreatedAt = Convert.ToDateTime(row["CreatedAt"])
                });
            }
            return list;
        }

        public static List<Product> GetProducts()
        {
            return GetProducts(null, null, false);
        }

        public static Product GetProductById(int id)
        {
            string sql = @"
                SELECT p.*, c.Name AS CategoryName, s.Name AS SupplierName
                FROM Products p
                LEFT JOIN Categories c ON p.CategoryId = c.Id
                LEFT JOIN Suppliers s ON p.SupplierId = s.Id
                WHERE p.Id = @Id;
            ";
            DataTable dt = ExecuteQuery(sql, new SqlParameter("@Id", id));
            if (dt.Rows.Count == 0) return null;
            DataRow row = dt.Rows[0];
            return new Product
            {
                Id = Convert.ToInt32(row["Id"]),
                Code = row["Code"].ToString(),
                Barcode = row["Barcode"] != DBNull.Value ? row["Barcode"].ToString() : null,
                Name = row["Name"].ToString(),
                CategoryId = row["CategoryId"] != DBNull.Value ? (int?)Convert.ToInt32(row["CategoryId"]) : null,
                CategoryName = row["CategoryName"] != DBNull.Value ? row["CategoryName"].ToString() : null,
                SupplierId = row["SupplierId"] != DBNull.Value ? (int?)Convert.ToInt32(row["SupplierId"]) : null,
                SupplierName = row["SupplierName"] != DBNull.Value ? row["SupplierName"].ToString() : null,
                Unit = row["Unit"].ToString(),
                CostPrice = Convert.ToDecimal(row["CostPrice"]),
                SellingPrice = Convert.ToDecimal(row["SellingPrice"]),
                StockQuantity = Convert.ToInt32(row["StockQuantity"]),
                MinStockAlert = Convert.ToInt32(row["MinStockAlert"]),
                ImageIcon = row["ImageIcon"] != DBNull.Value ? row["ImageIcon"].ToString() : "📦",
                CreatedAt = Convert.ToDateTime(row["CreatedAt"])
            };
        }

        public static int AddProduct(string code, string barcode, string name, int? categoryId, int? supplierId, string unit, decimal costPrice, decimal sellingPrice, int stockQuantity, int minAlert, string icon)
        {
            string sql = @"
                INSERT INTO Products (Code, Barcode, Name, CategoryId, SupplierId, Unit, CostPrice, SellingPrice, StockQuantity, MinStockAlert, ImageIcon)
                VALUES (@Code, @Barcode, @Name, @CatId, @SupId, @Unit, @Cost, @Sell, @Stock, @Alert, @Icon);
            ";
            return ExecuteNonQuery(sql,
                new SqlParameter("@Code", code),
                new SqlParameter("@Barcode", (object)barcode ?? DBNull.Value),
                new SqlParameter("@Name", name),
                new SqlParameter("@CatId", (object)categoryId ?? DBNull.Value),
                new SqlParameter("@SupId", (object)supplierId ?? DBNull.Value),
                new SqlParameter("@Unit", unit ?? "Cái"),
                new SqlParameter("@Cost", costPrice),
                new SqlParameter("@Sell", sellingPrice),
                new SqlParameter("@Stock", stockQuantity),
                new SqlParameter("@Alert", minAlert),
                new SqlParameter("@Icon", icon ?? "📦"));
        }

        public static int UpdateProduct(int id, string barcode, string name, int? categoryId, int? supplierId, string unit, decimal costPrice, decimal sellingPrice, int stockQuantity, int minAlert, string icon)
        {
            string sql = @"
                UPDATE Products
                SET Barcode = @Barcode, Name = @Name, CategoryId = @CatId, SupplierId = @SupId,
                    Unit = @Unit, CostPrice = @Cost, SellingPrice = @Sell, StockQuantity = @Stock,
                    MinStockAlert = @Alert, ImageIcon = @Icon
                WHERE Id = @Id;
            ";
            return ExecuteNonQuery(sql,
                new SqlParameter("@Id", id),
                new SqlParameter("@Barcode", (object)barcode ?? DBNull.Value),
                new SqlParameter("@Name", name),
                new SqlParameter("@CatId", (object)categoryId ?? DBNull.Value),
                new SqlParameter("@SupId", (object)supplierId ?? DBNull.Value),
                new SqlParameter("@Unit", unit ?? "Cái"),
                new SqlParameter("@Cost", costPrice),
                new SqlParameter("@Sell", sellingPrice),
                new SqlParameter("@Stock", stockQuantity),
                new SqlParameter("@Alert", minAlert),
                new SqlParameter("@Icon", icon ?? "📦"));
        }

        public static int DeleteProduct(int id)
        {
            return ExecuteNonQuery("DELETE FROM Products WHERE Id = @Id;", new SqlParameter("@Id", id));
        }

        // ==================== POS & INVOICES ====================
        public static List<Invoice> GetInvoices(string query, string fromDate, string toDate)
        {
            string sql = @"
                SELECT i.*, 
                       ISNULL(c.Name, N'Khách vãng lai') AS CustomerName,
                       c.Phone AS CustomerPhone,
                       ISNULL(e.Name, N'Thu ngân') AS EmployeeName,
                       (SELECT COUNT(*) FROM InvoiceDetails d WHERE d.InvoiceId = i.Id) AS ItemCount
                FROM Invoices i
                LEFT JOIN Customers c ON i.CustomerId = c.Id
                LEFT JOIN Employees e ON i.EmployeeId = e.Id
                WHERE 1=1
            ";
            var parameters = new List<SqlParameter>();
            if (!string.IsNullOrEmpty(query))
            {
                sql += " AND (i.Code LIKE @Q OR c.Name LIKE @Q OR c.Phone LIKE @Q)";
                parameters.Add(new SqlParameter("@Q", "%" + query.Trim() + "%"));
            }
            if (!string.IsNullOrEmpty(fromDate))
            {
                sql += " AND CAST(i.InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)";
                parameters.Add(new SqlParameter("@FromDate", fromDate));
            }
            if (!string.IsNullOrEmpty(toDate))
            {
                sql += " AND CAST(i.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)";
                parameters.Add(new SqlParameter("@ToDate", toDate));
            }
            sql += " ORDER BY i.Id DESC;";

            DataTable dt = ExecuteQuery(sql, parameters.ToArray());
            var list = new List<Invoice>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new Invoice
                {
                    Id = Convert.ToInt32(row["Id"]),
                    Code = row["Code"].ToString(),
                    CustomerId = row["CustomerId"] != DBNull.Value ? (int?)Convert.ToInt32(row["CustomerId"]) : null,
                    CustomerName = row["CustomerName"].ToString(),
                    CustomerPhone = row["CustomerPhone"] != DBNull.Value ? row["CustomerPhone"].ToString() : null,
                    EmployeeId = row["EmployeeId"] != DBNull.Value ? (int?)Convert.ToInt32(row["EmployeeId"]) : null,
                    EmployeeName = row["EmployeeName"].ToString(),
                    Subtotal = Convert.ToDecimal(row["Subtotal"]),
                    Discount = Convert.ToDecimal(row["Discount"]),
                    TotalAmount = Convert.ToDecimal(row["TotalAmount"]),
                    CustomerPayment = Convert.ToDecimal(row["CustomerPayment"]),
                    ChangeAmount = Convert.ToDecimal(row["ChangeAmount"]),
                    PaymentMethod = row["PaymentMethod"].ToString(),
                    Notes = row["Notes"] != DBNull.Value ? row["Notes"].ToString() : null,
                    InvoiceDate = Convert.ToDateTime(row["InvoiceDate"]),
                    ItemCount = Convert.ToInt32(row["ItemCount"])
                });
            }
            return list;
        }

        public static Invoice GetInvoiceById(int id)
        {
            string sql = @"
                SELECT i.*, 
                       ISNULL(c.Name, N'Khách vãng lai') AS CustomerName,
                       c.Phone AS CustomerPhone,
                       c.Address AS CustomerAddress,
                       ISNULL(e.Name, N'Thu ngân') AS EmployeeName
                FROM Invoices i
                LEFT JOIN Customers c ON i.CustomerId = c.Id
                LEFT JOIN Employees e ON i.EmployeeId = e.Id
                WHERE i.Id = @Id;
            ";
            DataTable dt = ExecuteQuery(sql, new SqlParameter("@Id", id));
            if (dt.Rows.Count == 0) return null;
            DataRow row = dt.Rows[0];
            var invoice = new Invoice
            {
                Id = Convert.ToInt32(row["Id"]),
                Code = row["Code"].ToString(),
                CustomerId = row["CustomerId"] != DBNull.Value ? (int?)Convert.ToInt32(row["CustomerId"]) : null,
                CustomerName = row["CustomerName"].ToString(),
                CustomerPhone = row["CustomerPhone"] != DBNull.Value ? row["CustomerPhone"].ToString() : null,
                CustomerAddress = row["CustomerAddress"] != DBNull.Value ? row["CustomerAddress"].ToString() : null,
                EmployeeId = row["EmployeeId"] != DBNull.Value ? (int?)Convert.ToInt32(row["EmployeeId"]) : null,
                EmployeeName = row["EmployeeName"].ToString(),
                Subtotal = Convert.ToDecimal(row["Subtotal"]),
                Discount = Convert.ToDecimal(row["Discount"]),
                TotalAmount = Convert.ToDecimal(row["TotalAmount"]),
                CustomerPayment = Convert.ToDecimal(row["CustomerPayment"]),
                ChangeAmount = Convert.ToDecimal(row["ChangeAmount"]),
                PaymentMethod = row["PaymentMethod"].ToString(),
                Notes = row["Notes"] != DBNull.Value ? row["Notes"].ToString() : null,
                InvoiceDate = Convert.ToDateTime(row["InvoiceDate"])
            };

            string detailSql = "SELECT * FROM InvoiceDetails WHERE InvoiceId = @InvId;";
            DataTable detailDt = ExecuteQuery(detailSql, new SqlParameter("@InvId", id));
            foreach (DataRow dRow in detailDt.Rows)
            {
                invoice.Items.Add(new InvoiceDetail
                {
                    Id = Convert.ToInt32(dRow["Id"]),
                    InvoiceId = Convert.ToInt32(dRow["InvoiceId"]),
                    ProductId = Convert.ToInt32(dRow["ProductId"]),
                    ProductName = dRow["ProductName"].ToString(),
                    Unit = dRow["Unit"].ToString(),
                    Quantity = Convert.ToInt32(dRow["Quantity"]),
                    CostPrice = Convert.ToDecimal(dRow["CostPrice"]),
                    SellingPrice = Convert.ToDecimal(dRow["SellingPrice"]),
                    TotalPrice = Convert.ToDecimal(dRow["TotalPrice"])
                });
            }
            return invoice;
        }

        public static Invoice CreateInvoiceTransaction(int? customerId, int? employeeId, List<CartItem> items, decimal discount, decimal customerPayment, string paymentMethod, string notes)
        {
            if (items == null || items.Count == 0)
                throw new Exception("Giỏ hàng đang trống, không thể thanh toán!");

            using (var conn = GetConnection())
            using (var trans = conn.BeginTransaction())
            {
                try
                {
                    // 1. Kiểm tra tồn kho
                    foreach (var item in items)
                    {
                        using (var checkCmd = new SqlCommand("SELECT Name, StockQuantity, Unit, CostPrice FROM Products WHERE Id = @Id;", conn, trans))
                        {
                            checkCmd.Parameters.AddWithValue("@Id", item.ProductId);
                            using (var reader = checkCmd.ExecuteReader())
                            {
                                if (!reader.Read())
                                    throw new Exception(string.Format("Sản phẩm #{0} không tồn tại!", item.ProductId));
                                int stock = Convert.ToInt32(reader["StockQuantity"]);
                                string name = reader["Name"].ToString();
                                string unit = reader["Unit"].ToString();
                                if (stock < item.Quantity)
                                    throw new Exception(string.Format("Sản phẩm \"{0}\" chỉ còn {1} {2} trong kho, không đủ bán!", name, stock, unit));
                            }
                        }
                    }

                    // 2. Tính tiền
                    decimal subtotal = 0;
                    foreach (var item in items) subtotal += item.TotalPrice;
                    decimal totalAmount = Math.Max(0, subtotal - discount);
                    decimal changeAmount = Math.Max(0, customerPayment - totalAmount);
                    string code = "HD" + DateTime.Now.ToString("yyyyMMdd") + new Random().Next(1000, 9999);

                    // 3. Thêm hóa đơn
                    int invoiceId;
                    string insertInvSql = @"
                        INSERT INTO Invoices (Code, CustomerId, EmployeeId, Subtotal, Discount, TotalAmount, CustomerPayment, ChangeAmount, PaymentMethod, Notes, InvoiceDate)
                        VALUES (@Code, @CustId, @EmpId, @Subtotal, @Discount, @Total, @Payment, @Change, @Method, @Notes, GETDATE());
                        SELECT SCOPE_IDENTITY();
                    ";
                    using (var cmd = new SqlCommand(insertInvSql, conn, trans))
                    {
                        cmd.Parameters.AddWithValue("@Code", code);
                        cmd.Parameters.AddWithValue("@CustId", (object)customerId ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@EmpId", (object)employeeId ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@Subtotal", subtotal);
                        cmd.Parameters.AddWithValue("@Discount", discount);
                        cmd.Parameters.AddWithValue("@Total", totalAmount);
                        cmd.Parameters.AddWithValue("@Payment", customerPayment);
                        cmd.Parameters.AddWithValue("@Change", changeAmount);
                        cmd.Parameters.AddWithValue("@Method", paymentMethod ?? "Tiền mặt");
                        cmd.Parameters.AddWithValue("@Notes", (object)notes ?? DBNull.Value);
                        invoiceId = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    // 4. Thêm chi tiết và trừ kho
                    foreach (var item in items)
                    {
                        decimal costPrice = 0;
                        string getCostSql = "SELECT CostPrice FROM Products WHERE Id = @Id;";
                        using (var costCmd = new SqlCommand(getCostSql, conn, trans))
                        {
                            costCmd.Parameters.AddWithValue("@Id", item.ProductId);
                            object cObj = costCmd.ExecuteScalar();
                            if (cObj != null) costPrice = Convert.ToDecimal(cObj);
                        }

                        string insertDetailSql = @"
                            INSERT INTO InvoiceDetails (InvoiceId, ProductId, ProductName, Unit, Quantity, CostPrice, SellingPrice, TotalPrice)
                            VALUES (@InvId, @ProdId, @Name, @Unit, @Qty, @Cost, @Sell, @Total);
                        ";
                        using (var dCmd = new SqlCommand(insertDetailSql, conn, trans))
                        {
                            dCmd.Parameters.AddWithValue("@InvId", invoiceId);
                            dCmd.Parameters.AddWithValue("@ProdId", item.ProductId);
                            dCmd.Parameters.AddWithValue("@Name", item.Name);
                            dCmd.Parameters.AddWithValue("@Unit", item.Unit);
                            dCmd.Parameters.AddWithValue("@Qty", item.Quantity);
                            dCmd.Parameters.AddWithValue("@Cost", costPrice);
                            dCmd.Parameters.AddWithValue("@Sell", item.SellingPrice);
                            dCmd.Parameters.AddWithValue("@Total", item.TotalPrice);
                            dCmd.ExecuteNonQuery();
                        }

                        string updateStockSql = "UPDATE Products SET StockQuantity = StockQuantity - @Qty WHERE Id = @Id;";
                        using (var sCmd = new SqlCommand(updateStockSql, conn, trans))
                        {
                            sCmd.Parameters.AddWithValue("@Qty", item.Quantity);
                            sCmd.Parameters.AddWithValue("@Id", item.ProductId);
                            sCmd.ExecuteNonQuery();
                        }
                    }

                    // 5. Cập nhật tích điểm khách hàng nếu có (10k = 1 điểm)
                    if (customerId.HasValue && customerId.Value > 0)
                    {
                        int addedPoints = (int)(totalAmount / 10000);
                        string custUpdateSql = @"
                            UPDATE Customers 
                            SET Points = Points + @Pts, TotalSpent = TotalSpent + @Spent 
                            WHERE Id = @Id;
                        ";
                        using (var custCmd = new SqlCommand(custUpdateSql, conn, trans))
                        {
                            custCmd.Parameters.AddWithValue("@Pts", addedPoints);
                            custCmd.Parameters.AddWithValue("@Spent", totalAmount);
                            custCmd.Parameters.AddWithValue("@Id", customerId.Value);
                            custCmd.ExecuteNonQuery();
                        }
                    }

                    trans.Commit();
                    return GetInvoiceById(invoiceId);
                }
                catch
                {
                    trans.Rollback();
                    throw;
                }
            }
        }

        // ==================== GOODS RECEIPTS ====================
        public static List<GoodsReceipt> GetGoodsReceipts()
        {
            string sql = @"
                SELECT r.*, s.Name AS SupplierName, s.Phone AS SupplierPhone, e.Name AS EmployeeName,
                       (SELECT COUNT(*) FROM GoodsReceiptDetails d WHERE d.ReceiptId = r.Id) AS ItemCount
                FROM GoodsReceipts r
                LEFT JOIN Suppliers s ON r.SupplierId = s.Id
                LEFT JOIN Employees e ON r.EmployeeId = e.Id
                ORDER BY r.Id DESC;
            ";
            DataTable dt = ExecuteQuery(sql);
            var list = new List<GoodsReceipt>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new GoodsReceipt
                {
                    Id = Convert.ToInt32(row["Id"]),
                    Code = row["Code"].ToString(),
                    SupplierId = row["SupplierId"] != DBNull.Value ? (int?)Convert.ToInt32(row["SupplierId"]) : null,
                    SupplierName = row["SupplierName"] != DBNull.Value ? row["SupplierName"].ToString() : null,
                    SupplierPhone = row["SupplierPhone"] != DBNull.Value ? row["SupplierPhone"].ToString() : null,
                    EmployeeId = row["EmployeeId"] != DBNull.Value ? (int?)Convert.ToInt32(row["EmployeeId"]) : null,
                    EmployeeName = row["EmployeeName"] != DBNull.Value ? row["EmployeeName"].ToString() : null,
                    TotalAmount = Convert.ToDecimal(row["TotalAmount"]),
                    Notes = row["Notes"] != DBNull.Value ? row["Notes"].ToString() : null,
                    ReceiptDate = Convert.ToDateTime(row["ReceiptDate"]),
                    ItemCount = Convert.ToInt32(row["ItemCount"])
                });
            }
            return list;
        }

        public static GoodsReceipt GetGoodsReceiptById(int id)
        {
            string sql = @"
                SELECT r.*, s.Name AS SupplierName, s.Phone AS SupplierPhone, s.Address AS SupplierAddress, e.Name AS EmployeeName
                FROM GoodsReceipts r
                LEFT JOIN Suppliers s ON r.SupplierId = s.Id
                LEFT JOIN Employees e ON r.EmployeeId = e.Id
                WHERE r.Id = @Id;
            ";
            DataTable dt = ExecuteQuery(sql, new SqlParameter("@Id", id));
            if (dt.Rows.Count == 0) return null;
            DataRow row = dt.Rows[0];
            var receipt = new GoodsReceipt
            {
                Id = Convert.ToInt32(row["Id"]),
                Code = row["Code"].ToString(),
                SupplierId = row["SupplierId"] != DBNull.Value ? (int?)Convert.ToInt32(row["SupplierId"]) : null,
                SupplierName = row["SupplierName"] != DBNull.Value ? row["SupplierName"].ToString() : null,
                SupplierPhone = row["SupplierPhone"] != DBNull.Value ? row["SupplierPhone"].ToString() : null,
                SupplierAddress = row["SupplierAddress"] != DBNull.Value ? row["SupplierAddress"].ToString() : null,
                EmployeeId = row["EmployeeId"] != DBNull.Value ? (int?)Convert.ToInt32(row["EmployeeId"]) : null,
                EmployeeName = row["EmployeeName"] != DBNull.Value ? row["EmployeeName"].ToString() : null,
                TotalAmount = Convert.ToDecimal(row["TotalAmount"]),
                Notes = row["Notes"] != DBNull.Value ? row["Notes"].ToString() : null,
                ReceiptDate = Convert.ToDateTime(row["ReceiptDate"])
            };

            string detailSql = @"
                SELECT d.*, p.Name AS ProductName, p.Code AS ProductCode, p.Unit
                FROM GoodsReceiptDetails d
                JOIN Products p ON d.ProductId = p.Id
                WHERE d.ReceiptId = @RecId;
            ";
            DataTable detailDt = ExecuteQuery(detailSql, new SqlParameter("@RecId", id));
            foreach (DataRow dRow in detailDt.Rows)
            {
                receipt.Items.Add(new GoodsReceiptDetail
                {
                    Id = Convert.ToInt32(dRow["Id"]),
                    ReceiptId = Convert.ToInt32(dRow["ReceiptId"]),
                    ProductId = Convert.ToInt32(dRow["ProductId"]),
                    ProductCode = dRow["ProductCode"].ToString(),
                    ProductName = dRow["ProductName"].ToString(),
                    Unit = dRow["Unit"].ToString(),
                    Quantity = Convert.ToInt32(dRow["Quantity"]),
                    CostPrice = Convert.ToDecimal(dRow["CostPrice"]),
                    TotalPrice = Convert.ToDecimal(dRow["TotalPrice"])
                });
            }
            return receipt;
        }

        public static int CreateGoodsReceiptTransaction(int supplierId, int? employeeId, List<GoodsReceiptDetail> items, string notes)
        {
            if (items == null || items.Count == 0)
                throw new Exception("Phiếu nhập cần có ít nhất 1 sản phẩm!");

            using (var conn = GetConnection())
            using (var trans = conn.BeginTransaction())
            {
                try
                {
                    decimal totalAmount = 0;
                    foreach (var it in items)
                    {
                        it.TotalPrice = it.Quantity * it.CostPrice;
                        totalAmount += it.TotalPrice;
                    }

                    string code = "PN" + DateTime.Now.ToString("yyyyMMdd") + new Random().Next(1000, 9999);
                    string insertRecSql = @"
                        INSERT INTO GoodsReceipts (Code, SupplierId, EmployeeId, TotalAmount, Notes, ReceiptDate)
                        VALUES (@Code, @SupId, @EmpId, @Total, @Notes, GETDATE());
                        SELECT SCOPE_IDENTITY();
                    ";
                    int receiptId;
                    using (var cmd = new SqlCommand(insertRecSql, conn, trans))
                    {
                        cmd.Parameters.AddWithValue("@Code", code);
                        cmd.Parameters.AddWithValue("@SupId", supplierId);
                        cmd.Parameters.AddWithValue("@EmpId", (object)employeeId ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@Total", totalAmount);
                        cmd.Parameters.AddWithValue("@Notes", (object)notes ?? DBNull.Value);
                        receiptId = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    string insertDetailSql = @"
                        INSERT INTO GoodsReceiptDetails (ReceiptId, ProductId, Quantity, CostPrice, TotalPrice)
                        VALUES (@RecId, @ProdId, @Qty, @Cost, @Total);
                    ";
                    string updateProdSql = @"
                        UPDATE Products 
                        SET StockQuantity = StockQuantity + @Qty, CostPrice = @Cost 
                        WHERE Id = @Id;
                    ";

                    foreach (var it in items)
                    {
                        using (var dCmd = new SqlCommand(insertDetailSql, conn, trans))
                        {
                            dCmd.Parameters.AddWithValue("@RecId", receiptId);
                            dCmd.Parameters.AddWithValue("@ProdId", it.ProductId);
                            dCmd.Parameters.AddWithValue("@Qty", it.Quantity);
                            dCmd.Parameters.AddWithValue("@Cost", it.CostPrice);
                            dCmd.Parameters.AddWithValue("@Total", it.TotalPrice);
                            dCmd.ExecuteNonQuery();
                        }

                        using (var pCmd = new SqlCommand(updateProdSql, conn, trans))
                        {
                            pCmd.Parameters.AddWithValue("@Qty", it.Quantity);
                            pCmd.Parameters.AddWithValue("@Cost", it.CostPrice);
                            pCmd.Parameters.AddWithValue("@Id", it.ProductId);
                            pCmd.ExecuteNonQuery();
                        }
                    }

                    trans.Commit();
                    return receiptId;
                }
                catch
                {
                    trans.Rollback();
                    throw;
                }
            }
        }

        // ==================== INVENTORY & ADJUSTMENTS ====================
        public static DataTable GetInventorySummary()
        {
            string sql = @"
                SELECT 
                    COUNT(*) AS TotalProducts,
                    ISNULL(SUM(StockQuantity), 0) AS TotalUnits,
                    ISNULL(SUM(StockQuantity * CostPrice), 0) AS TotalValue,
                    SUM(CASE WHEN StockQuantity <= MinStockAlert AND StockQuantity > 0 THEN 1 ELSE 0 END) AS LowCount,
                    SUM(CASE WHEN StockQuantity <= 0 THEN 1 ELSE 0 END) AS OutCount
                FROM Products;
            ";
            return ExecuteQuery(sql);
        }

        public static int AdjustStock(int productId, int newQuantity, string reason, int? employeeId)
        {
            Product p = GetProductById(productId);
            if (p == null) throw new Exception("Không tìm thấy sản phẩm!");

            int oldQuantity = p.StockQuantity;
            int diff = newQuantity - oldQuantity;
            string code = "KK" + DateTime.Now.ToString("yyyyMMdd") + new Random().Next(100, 999);

            using (var conn = GetConnection())
            using (var trans = conn.BeginTransaction())
            {
                try
                {
                    using (var uCmd = new SqlCommand("UPDATE Products SET StockQuantity = @NewQty WHERE Id = @Id;", conn, trans))
                    {
                        uCmd.Parameters.AddWithValue("@NewQty", newQuantity);
                        uCmd.Parameters.AddWithValue("@Id", productId);
                        uCmd.ExecuteNonQuery();
                    }

                    string insertAdjSql = @"
                        INSERT INTO StockAdjustments (Code, ProductId, OldQuantity, NewQuantity, ChangeQuantity, Reason, EmployeeId, AdjustedAt)
                        VALUES (@Code, @ProdId, @OldQty, @NewQty, @ChangeQty, @Reason, @EmpId, GETDATE());
                    ";
                    using (var aCmd = new SqlCommand(insertAdjSql, conn, trans))
                    {
                        aCmd.Parameters.AddWithValue("@Code", code);
                        aCmd.Parameters.AddWithValue("@ProdId", productId);
                        aCmd.Parameters.AddWithValue("@OldQty", oldQuantity);
                        aCmd.Parameters.AddWithValue("@NewQty", newQuantity);
                        aCmd.Parameters.AddWithValue("@ChangeQty", diff);
                        aCmd.Parameters.AddWithValue("@Reason", (object)reason ?? "Kiểm kê kho");
                        aCmd.Parameters.AddWithValue("@EmpId", (object)employeeId ?? DBNull.Value);
                        aCmd.ExecuteNonQuery();
                    }

                    trans.Commit();
                    return diff;
                }
                catch
                {
                    trans.Rollback();
                    throw;
                }
            }
        }

        public static List<StockAdjustment> GetStockAdjustments(int limit)
        {
            string sql = string.Format(@"
                SELECT TOP ({0})
                    a.*, p.Name AS ProductName, p.Code AS ProductCode, p.Unit,
                    ISNULL(e.Name, N'Nhân viên') AS EmployeeName
                FROM StockAdjustments a
                JOIN Products p ON a.ProductId = p.Id
                LEFT JOIN Employees e ON a.EmployeeId = e.Id
                ORDER BY a.Id DESC;
            ", limit);
            DataTable dt = ExecuteQuery(sql);
            var list = new List<StockAdjustment>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new StockAdjustment
                {
                    Id = Convert.ToInt32(row["Id"]),
                    Code = row["Code"].ToString(),
                    ProductId = Convert.ToInt32(row["ProductId"]),
                    ProductCode = row["ProductCode"].ToString(),
                    ProductName = row["ProductName"].ToString(),
                    Unit = row["Unit"].ToString(),
                    OldQuantity = Convert.ToInt32(row["OldQuantity"]),
                    NewQuantity = Convert.ToInt32(row["NewQuantity"]),
                    ChangeQuantity = Convert.ToInt32(row["ChangeQuantity"]),
                    Reason = row["Reason"] != DBNull.Value ? row["Reason"].ToString() : null,
                    EmployeeId = row["EmployeeId"] != DBNull.Value ? (int?)Convert.ToInt32(row["EmployeeId"]) : null,
                    EmployeeName = row["EmployeeName"].ToString(),
                    AdjustedAt = Convert.ToDateTime(row["AdjustedAt"])
                });
            }
            return list;
        }

        // ==================== REPORTS ====================
        public static DataTable GetCategorySalesReport()
        {
            string sql = @"
                SELECT 
                    c.Id, c.Name,
                    ISNULL(SUM(d.TotalPrice), 0) AS Revenue,
                    ISNULL(SUM(d.Quantity), 0) AS UnitsSold
                FROM Categories c
                LEFT JOIN Products p ON p.CategoryId = c.Id
                LEFT JOIN InvoiceDetails d ON d.ProductId = p.Id
                GROUP BY c.Id, c.Name
                ORDER BY Revenue DESC;
            ";
            return ExecuteQuery(sql);
        }

        public static DataTable GetTop10ProductsReport()
        {
            string sql = @"
                SELECT TOP 10
                    p.Id, p.Name, p.Code, p.Unit, p.ImageIcon,
                    ISNULL(SUM(d.Quantity), 0) AS TotalSold,
                    ISNULL(SUM(d.TotalPrice), 0) AS TotalRevenue,
                    ISNULL(SUM(d.TotalPrice - (d.Quantity * d.CostPrice)), 0) AS TotalProfit
                FROM Products p
                JOIN InvoiceDetails d ON p.Id = d.ProductId
                GROUP BY p.Id, p.Name, p.Code, p.Unit, p.ImageIcon
                ORDER BY TotalSold DESC;
            ";
            return ExecuteQuery(sql);
        }

        public static DataTable GetPaymentMethodsReport()
        {
            string sql = @"
                SELECT PaymentMethod, COUNT(*) AS Count, ISNULL(SUM(TotalAmount), 0) AS Total
                FROM Invoices
                GROUP BY PaymentMethod;
            ";
            return ExecuteQuery(sql);
        }
    }
}
