using System;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using System.Web.Services;
using System.Web.UI;
using QuanLiCuaHangTapHoa.DAL;
using QuanLiCuaHangTapHoa.Models;

namespace QuanLiCuaHangTapHoa
{
    public partial class POS : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadData();
            }
        }

        private void LoadData()
        {
            try
            {
                // Categories
                rptCategories.DataSource = DatabaseHelper.GetCategories();
                rptCategories.DataBind();

                // Products
                rptProducts.DataSource = DatabaseHelper.GetProducts();
                rptProducts.DataBind();

                // Customers
                rptCustomers.DataSource = DatabaseHelper.GetCustomers();
                rptCustomers.DataBind();

                // Employees
                rptEmployees.DataSource = DatabaseHelper.GetEmployees();
                rptEmployees.DataBind();
            }
            catch (Exception ex)
            {
                // Handle error
            }
        }

        public class CheckoutRequest
        {
            public int customerId { get; set; }
            public int employeeId { get; set; }
            public List<CartItem> items { get; set; }
            public decimal discount { get; set; }
            public decimal customerPayment { get; set; }
            public string paymentMethod { get; set; }
            public string notes { get; set; }
        }

        [WebMethod]
        public static string Checkout(string json)
        {
            var serializer = new JavaScriptSerializer();
            try
            {
                var req = serializer.Deserialize<CheckoutRequest>(json);
                if (req == null || req.items == null || req.items.Count == 0)
                {
                    return serializer.Serialize(new { Success = false, Error = "Giỏ hàng rỗng!" });
                }

                int? custId = req.customerId > 0 ? (int?)req.customerId : null;
                int? empId = req.employeeId > 0 ? (int?)req.employeeId : null;

                Invoice inv = DatabaseHelper.CreateInvoiceTransaction(
                    custId,
                    empId,
                    req.items,
                    req.discount,
                    req.customerPayment,
                    req.paymentMethod,
                    req.notes
                );

                return serializer.Serialize(new
                {
                    Success = true,
                    Invoice = inv
                });
            }
            catch (Exception ex)
            {
                return serializer.Serialize(new
                {
                    Success = false,
                    Error = ex.Message
                });
            }
        }
    }
}
