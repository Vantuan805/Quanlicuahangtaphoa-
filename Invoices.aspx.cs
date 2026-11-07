using System;
using System.Web.Script.Serialization;
using System.Web.Services;
using System.Web.UI;
using QuanLiCuaHangTapHoa.DAL;
using QuanLiCuaHangTapHoa.Models;

namespace QuanLiCuaHangTapHoa
{
    public partial class Invoices : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadInvoices();
            }
        }

        private void LoadInvoices()
        {
            try
            {
                string search = txtSearch.Text.Trim();
                string fromDate = txtFromDate.Text.Trim();
                string toDate = txtToDate.Text.Trim();

                var list = DatabaseHelper.GetInvoices(
                    string.IsNullOrEmpty(search) ? null : search,
                    string.IsNullOrEmpty(fromDate) ? null : fromDate,
                    string.IsNullOrEmpty(toDate) ? null : toDate
                );

                litCount.Text = list.Count.ToString();
                rptInvoices.DataSource = list;
                rptInvoices.DataBind();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }

        protected void btnFilter_Click(object sender, EventArgs e)
        {
            LoadInvoices();
        }

        protected void btnReset_Click(object sender, EventArgs e)
        {
            txtSearch.Text = "";
            txtFromDate.Text = "";
            txtToDate.Text = "";
            LoadInvoices();
        }

        [WebMethod]
        public static string GetInvoice(int id)
        {
            var serializer = new JavaScriptSerializer();
            try
            {
                Invoice inv = DatabaseHelper.GetInvoiceById(id);
                if (inv == null)
                {
                    return serializer.Serialize(new { Success = false, Error = "Không tìm thấy hóa đơn!" });
                }
                return serializer.Serialize(new { Success = true, Invoice = inv });
            }
            catch (Exception ex)
            {
                return serializer.Serialize(new { Success = false, Error = ex.Message });
            }
        }
    }
}
