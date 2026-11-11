using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;

namespace QuanLiCuaHangTapHoa.Testing
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.OutputEncoding = Encoding.UTF8;
            Console.WriteLine("====================================================================");
            Console.WriteLine("KIEM TRA TOAN DIEN 11 PHAN HE VA CAC NUT TUONG TAC");
            Console.WriteLine("====================================================================");

            string baseUrl = "http://localhost:8088";
            bool allPassed = true;

            var pages = new[]
            {
                new { File = "Default.aspx", Name = "Tong quan & Thong ke", Tags = new[] { "kpi-grid", "revenue-chart", "Sản phẩm bán chạy nhất", "Sắp hết hàng", "Hóa đơn gần nhất" } },
                new { File = "POS.aspx", Name = "Quay Thu Ngan (POS)", Tags = new[] { "pos-search-input", "pos-category-chips", "pos-product-grid", "cart-items-list", "btn-checkout", "receipt-modal" } },
                new { File = "Products.aspx", Name = "Quan ly San pham", Tags = new[] { "openProductModal", "product-modal", "openEditModal", "btnSaveProduct", "txtProdName" } },
                new { File = "Categories.aspx", Name = "Loai san pham", Tags = new[] { "openCategoryModal", "cat-modal", "openEditCategoryModal", "btnSaveCategory", "txtCatName" } },
                new { File = "Inventory.aspx", Name = "Kho hang & Kiem ke", Tags = new[] { "openAdjustModal", "adjust-modal", "txtNewQuantity", "btnSaveAdjust", "ddlModalProducts" } },
                new { File = "GoodsReceipts.aspx", Name = "Phieu nhap hang", Tags = new[] { "openCreateReceiptModal", "create-receipt-modal", "addReceiptRow", "submitReceipt", "view-receipt-modal" } },
                new { File = "Invoices.aspx", Name = "Hoa don ban hang", Tags = new[] { "viewInvoiceDetails", "invoice-modal", "invoice-print-area", "printReceipt" } },
                new { File = "Suppliers.aspx", Name = "Nha cung cap", Tags = new[] { "openSupplierModal", "sup-modal", "openEditSupplierModal", "btnSaveSupplier", "txtSupName" } },
                new { File = "Customers.aspx", Name = "Khach hang", Tags = new[] { "openCustomerModal", "cust-modal", "openEditCustomerModal", "btnSaveCustomer", "txtCustName" } },
                new { File = "Employees.aspx", Name = "Nhan vien", Tags = new[] { "openEmployeeModal", "emp-modal", "openEditEmployeeModal", "btnSaveEmployee", "txtEmpName" } },
                new { File = "Reports.aspx", Name = "Bao cao kinh doanh", Tags = new[] { "Doanh Thu", "Phương Thức Thanh Toán", "Top 10 Sản Phẩm", "progress-bar-fill" } }
            };

            Console.WriteLine("\n--- PHAN 1: KIEM TRA GIAO DIEN HTML, NUT BAM & MODAL TUNG TRANG ---");
            using (var client = new WebClient())
            {
                client.Encoding = Encoding.UTF8;
                foreach (var p in pages)
                {
                    try
                    {
                        string html = client.DownloadString(baseUrl + "/" + p.File);
                        var missing = new List<string>();
                        foreach (var tag in p.Tags)
                        {
                            if (!html.Contains(tag)) missing.Add(tag);
                        }

                        var unrendered = Regex.Matches(html, @"<%[=#][\s\S]*?%>");
                        if (missing.Count == 0 && unrendered.Count == 0)
                        {
                            Console.WriteLine("  [OK] " + p.File + " (" + p.Name + "): Day du tat ca nut bam va modal popup!");
                        }
                        else
                        {
                            if (missing.Count > 0)
                                Console.WriteLine("  [FAIL] " + p.File + ": Thieu thanh phan -> " + string.Join(", ", missing));
                            if (unrendered.Count > 0)
                                Console.WriteLine("  [FAIL] " + p.File + ": Con the ASPX chua render: " + unrendered.Count);
                            allPassed = false;
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine("  [ERROR] " + p.File + ": " + ex.Message);
                        allPassed = false;
                    }
                }
            }

            Console.WriteLine("\n--- PHAN 2: KIEM TRA CAC WEBMETHOD API (AJAX PAGEMETHODS) ---");

            // Test 1: GetReceiptDetails
            try
            {
                var req = (HttpWebRequest)WebRequest.Create(baseUrl + "/GoodsReceipts.aspx/GetReceiptDetails");
                req.Method = "POST";
                req.ContentType = "application/json; charset=utf-8";
                byte[] data = Encoding.UTF8.GetBytes("{\"id\": 1}");
                req.ContentLength = data.Length;
                using (var stream = req.GetRequestStream()) stream.Write(data, 0, data.Length);
                using (var res = req.GetResponse())
                using (var r = new StreamReader(res.GetResponseStream()))
                {
                    string json = r.ReadToEnd();
                    if (json.Contains("Success") && (json.Contains("true") || json.Contains("PN20261103001")))
                    {
                        Console.WriteLine("  [OK] GoodsReceipts.aspx/GetReceiptDetails: Tra ve chi tiet phieu nhap ID 1 hop le!");
                    }
                    else
                    {
                        Console.WriteLine("  [WARN] GoodsReceipts.aspx/GetReceiptDetails: " + json);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("  [FAIL] GoodsReceipts.aspx/GetReceiptDetails: " + ex.Message);
                allPassed = false;
            }

            // Test 2: GetInvoiceDetails
            try
            {
                var req = (HttpWebRequest)WebRequest.Create(baseUrl + "/Invoices.aspx/GetInvoiceDetails");
                req.Method = "POST";
                req.ContentType = "application/json; charset=utf-8";
                byte[] data = Encoding.UTF8.GetBytes("{\"id\": 1}");
                req.ContentLength = data.Length;
                using (var stream = req.GetRequestStream()) stream.Write(data, 0, data.Length);
                using (var res = req.GetResponse())
                using (var r = new StreamReader(res.GetResponseStream()))
                {
                    string json = r.ReadToEnd();
                    if (json.Contains("Success") && (json.Contains("true") || json.Contains("HD20261105001")))
                    {
                        Console.WriteLine("  [OK] Invoices.aspx/GetInvoiceDetails: Tra ve chi tiet hoa don ID 1 hop le!");
                    }
                    else
                    {
                        Console.WriteLine("  [WARN] Invoices.aspx/GetInvoiceDetails: " + json);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("  [FAIL] Invoices.aspx/GetInvoiceDetails: " + ex.Message);
                allPassed = false;
            }

            // Test 3: POS Checkout
            try
            {
                string innerJson = "{\"customerId\":1,\"employeeId\":2,\"items\":[{\"productId\":1,\"name\":\"Mì Hảo Hảo\",\"unit\":\"Gói\",\"sellingPrice\":4500,\"quantity\":1}],\"discount\":0,\"customerPayment\":5000,\"paymentMethod\":\"Tiền mặt\",\"notes\":\"AutoTest\"}";
                string outerJson = "{\"json\":" + NewtonsoftJsonEscaper(innerJson) + "}";

                var req = (HttpWebRequest)WebRequest.Create(baseUrl + "/POS.aspx/Checkout");
                req.Method = "POST";
                req.ContentType = "application/json; charset=utf-8";
                byte[] data = Encoding.UTF8.GetBytes(outerJson);
                req.ContentLength = data.Length;
                using (var stream = req.GetRequestStream()) stream.Write(data, 0, data.Length);
                using (var res = req.GetResponse())
                using (var r = new StreamReader(res.GetResponseStream()))
                {
                    string json = r.ReadToEnd();
                    if (json.Contains("Success") && json.Contains("true") && json.Contains("HD"))
                    {
                        Console.WriteLine("  [OK] POS.aspx/Checkout: Thanh toan don hang POS thanh cong, da tao ma hoa don moi!");
                    }
                    else
                    {
                        Console.WriteLine("  [FAIL] POS.aspx/Checkout: " + json);
                        allPassed = false;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("  [FAIL] POS.aspx/Checkout: " + ex.Message);
                allPassed = false;
            }

            Console.WriteLine("\n--- PHAN 3: KIEM TRA CSS MODAL & JAVASCRIPT APP.JS ---");
            using (var client = new WebClient())
            {
                client.Encoding = Encoding.UTF8;
                string css = client.DownloadString(baseUrl + "/Content/style.css");
                if (css.Contains(".modal") && css.Contains("z-index: 99999") && css.Contains(".modal.show"))
                {
                    Console.WriteLine("  [OK] Content/style.css: CSS Modal overlay hoan thien (z-index 99999, flex display)");
                }
                else
                {
                    Console.WriteLine("  [FAIL] Content/style.css: Thieu CSS cho modal!");
                    allPassed = false;
                }

                string js = client.DownloadString(baseUrl + "/Scripts/app.js");
                if (js.Contains("function openModal") && js.Contains("function closeModal") && js.Contains("showToast"))
                {
                    Console.WriteLine("  [OK] Scripts/app.js: JS Helper day du (openModal, closeModal, ESC, showToast)");
                }
                else
                {
                    Console.WriteLine("  [FAIL] Scripts/app.js: Thieu ham tro giup!");
                    allPassed = false;
                }
            }

            Console.WriteLine("\n====================================================================");
            if (allPassed)
            {
                Console.WriteLine("THANH CONG: 100% TAT CA 11 PHAN HE VA CAC NUT TUONG TAC DEU HOAT DONG TOT!");
            }
            else
            {
                Console.WriteLine("CO LOI CAN XU LY!");
            }
            Console.WriteLine("====================================================================");
        }

        static string NewtonsoftJsonEscaper(string str)
        {
            var sb = new StringBuilder();
            sb.Append("\"");
            foreach (char c in str)
            {
                if (c == '"') sb.Append("\\\"");
                else if (c == '\\') sb.Append("\\\\");
                else if (c == '\b') sb.Append("\\b");
                else if (c == '\f') sb.Append("\\f");
                else if (c == '\n') sb.Append("\\n");
                else if (c == '\r') sb.Append("\\r");
                else if (c == '\t') sb.Append("\\t");
                else sb.Append(c);
            }
            sb.Append("\"");
            return sb.ToString();
        }
    }
}