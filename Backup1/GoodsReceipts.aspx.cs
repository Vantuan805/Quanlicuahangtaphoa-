using System;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using System.Web.Services;
using System.Web.UI;
using QuanLiCuaHangTapHoa.DAL;
using QuanLiCuaHangTapHoa.Models;

namespace QuanLiCuaHangTapHoa
{
    public partial class GoodsReceipts : Page
    {
        public string ProductsJson = "[]";

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
                var receipts = DatabaseHelper.GetGoodsReceipts();
                litCount.Text = receipts.Count.ToString();
                rptReceipts.DataSource = receipts;
                rptReceipts.DataBind();

                var suppliers = DatabaseHelper.GetSuppliers();
                rptModalSuppliers.DataSource = suppliers;
                rptModalSuppliers.DataBind();

                var employees = DatabaseHelper.GetEmployees();
                rptModalEmployees.DataSource = employees;
                rptModalEmployees.DataBind();

                var products = DatabaseHelper.GetProducts();
                var serializer = new JavaScriptSerializer();
                ProductsJson = serializer.Serialize(products);
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi tải phiếu nhập: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }

        public class CreateReceiptRequest
        {
            public int SupplierId { get; set; }
            public int EmployeeId { get; set; }
            public string Notes { get; set; }
            public List<GoodsReceiptDetail> Items { get; set; }
        }

        [WebMethod]
        public static string CreateReceipt(string json)
        {
            var serializer = new JavaScriptSerializer();
            try
            {
                var req = serializer.Deserialize<CreateReceiptRequest>(json);
                if (req == null || req.SupplierId <= 0 || req.Items == null || req.Items.Count == 0)
                {
                    return serializer.Serialize(new { Success = false, Error = "Dữ liệu phiếu nhập không hợp lệ!" });
                }

                int? empId = req.EmployeeId > 0 ? (int?)req.EmployeeId : null;
                int id = DatabaseHelper.CreateGoodsReceiptTransaction(req.SupplierId, empId, req.Items, req.Notes);

                return serializer.Serialize(new { Success = true, Id = id });
            }
            catch (Exception ex)
            {
                return serializer.Serialize(new { Success = false, Error = ex.Message });
            }
        }

        [WebMethod]
        public static string GetReceiptDetails(int id)
        {
            var serializer = new JavaScriptSerializer();
            try
            {
                var receipt = DatabaseHelper.GetGoodsReceiptById(id);
                if (receipt == null)
                {
                    return serializer.Serialize(new { Success = false, Error = "Không tìm thấy phiếu nhập!" });
                }
                return serializer.Serialize(new { Success = true, Receipt = receipt });
            }
            catch (Exception ex)
            {
                return serializer.Serialize(new { Success = false, Error = ex.Message });
            }
        }
    }
}
