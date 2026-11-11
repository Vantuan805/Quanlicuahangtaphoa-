using System;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;
using QuanLiCuaHangTapHoa.DAL;

namespace QuanLiCuaHangTapHoa
{
    public partial class Inventory : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                if (!string.IsNullOrEmpty(Request.QueryString["status"]))
                {
                    ddlStatusFilter.SelectedValue = Request.QueryString["status"];
                }
                LoadSummary();
                LoadInventory();
                LoadModalData();
            }
        }

        private void LoadSummary()
        {
            try
            {
                DataTable dt = DatabaseHelper.GetInventorySummary();
                if (dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    litTotalProducts.Text = Convert.ToInt32(r["TotalProducts"]).ToString("N0");
                    litTotalUnits.Text = Convert.ToInt32(r["TotalUnits"]).ToString("N0");
                    litTotalValue.Text = string.Format("{0:N0} ₫", Convert.ToDecimal(r["TotalValue"]));
                    litLowCount.Text = Convert.ToInt32(r["LowCount"]).ToString();
                    litOutCount.Text = Convert.ToInt32(r["OutCount"]).ToString();
                }
            }
            catch { }
        }

        private void LoadInventory()
        {
            try
            {
                string search = txtSearch.Text.Trim();
                string status = ddlStatusFilter.SelectedValue;

                var list = DatabaseHelper.GetProducts(
                    string.IsNullOrEmpty(search) ? null : search,
                    null,
                    status == "low"
                );

                if (status == "out")
                {
                    list = list.FindAll(p => p.StockQuantity <= 0);
                }
                else if (status == "normal")
                {
                    list = list.FindAll(p => p.StockQuantity > p.MinStockAlert);
                }

                litFilteredCount.Text = list.Count.ToString();
                rptInventory.DataSource = list;
                rptInventory.DataBind();

                // Load Adjustments History
                var adjustments = DatabaseHelper.GetStockAdjustments(30);
                rptAdjustments.DataSource = adjustments;
                rptAdjustments.DataBind();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi tải kho: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }

        private void LoadModalData()
        {
            try
            {
                var prods = DatabaseHelper.GetProducts();
                ddlModalProducts.Items.Clear();
                foreach (var p in prods)
                {
                    var item = new ListItem(string.Format("{0} - {1}", p.Code, p.Name), p.Id.ToString());
                    item.Attributes.Add("data-stock", p.StockQuantity.ToString());
                    item.Attributes.Add("data-unit", p.Unit);
                    ddlModalProducts.Items.Add(item);
                }

                var emps = DatabaseHelper.GetEmployees();
                ddlModalEmployees.Items.Clear();
                foreach (var em in emps)
                {
                    ddlModalEmployees.Items.Add(new ListItem(string.Format("{0} ({1})", em.Name, em.Role), em.Id.ToString()));
                }
            }
            catch { }
        }

        protected void btnFilter_Click(object sender, EventArgs e)
        {
            LoadInventory();
        }

        protected void btnReset_Click(object sender, EventArgs e)
        {
            txtSearch.Text = "";
            ddlStatusFilter.SelectedValue = "all";
            LoadInventory();
        }

        protected void btnSaveAdjust_Click(object sender, EventArgs e)
        {
            try
            {
                int prodId = Convert.ToInt32(ddlModalProducts.SelectedValue);
                if (prodId <= 0)
                {
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Vui lòng chọn sản phẩm!', 'warning');", true);
                    return;
                }

                int newQty = 0;
                int.TryParse(txtNewQuantity.Text, out newQty);
                string reason = ddlReason.SelectedValue;
                int empId = Convert.ToInt32(ddlModalEmployees.SelectedValue);

                int diff = DatabaseHelper.AdjustStock(prodId, newQty, reason, empId > 0 ? (int?)empId : null);

                string diffStr = diff > 0 ? "+" + diff : diff.ToString();
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Kiểm kê thành công! Tồn kho đã cập nhật ({0}).', 'success');", diffStr), true);

                LoadSummary();
                LoadInventory();
                LoadModalData();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi điều chỉnh kho: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }
    }
}
