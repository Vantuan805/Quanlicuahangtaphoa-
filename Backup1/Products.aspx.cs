using System;
using System.Collections.Generic;
using System.Web.UI;
using System.Web.UI.WebControls;
using QuanLiCuaHangTapHoa.DAL;
using QuanLiCuaHangTapHoa.Models;

namespace QuanLiCuaHangTapHoa
{
    public partial class Products : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadDropdowns();
                LoadProducts();
            }
        }

        private void LoadDropdowns()
        {
            try
            {
                var categories = DatabaseHelper.GetCategories();
                ddlCategoryFilter.Items.Clear();
                ddlCategoryFilter.Items.Add(new ListItem("--- Tất cả loại hàng ---", "0"));
                ddlProdCategory.Items.Clear();
                ddlProdCategory.Items.Add(new ListItem("--- Chọn loại hàng ---", "0"));

                foreach (var c in categories)
                {
                    ddlCategoryFilter.Items.Add(new ListItem(c.Name, c.Id.ToString()));
                    ddlProdCategory.Items.Add(new ListItem(c.Name, c.Id.ToString()));
                }

                var suppliers = DatabaseHelper.GetSuppliers();
                ddlProdSupplier.Items.Clear();
                ddlProdSupplier.Items.Add(new ListItem("--- Chọn nhà cung cấp ---", "0"));
                foreach (var s in suppliers)
                {
                    ddlProdSupplier.Items.Add(new ListItem(s.Name, s.Id.ToString()));
                }
            }
            catch { }
        }

        private void LoadProducts()
        {
            try
            {
                string search = txtSearch.Text.Trim();
                int catId = Convert.ToInt32(ddlCategoryFilter.SelectedValue);
                bool lowStock = chkLowStockOnly.Checked;

                var list = DatabaseHelper.GetProducts(
                    string.IsNullOrEmpty(search) ? null : search,
                    catId > 0 ? (int?)catId : null,
                    lowStock
                );

                litTotalCount.Text = list.Count.ToString();
                rptProducts.DataSource = list;
                rptProducts.DataBind();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi tải sản phẩm: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }

        protected void btnFilter_Click(object sender, EventArgs e)
        {
            LoadProducts();
        }

        protected void btnResetFilter_Click(object sender, EventArgs e)
        {
            txtSearch.Text = "";
            ddlCategoryFilter.SelectedIndex = 0;
            chkLowStockOnly.Checked = false;
            LoadProducts();
        }

        protected void btnSaveProduct_Click(object sender, EventArgs e)
        {
            try
            {
                int id = Convert.ToInt32(hfProductId.Value);
                string name = txtProdName.Text.Trim();
                string barcode = txtProdBarcode.Text.Trim();
                int catId = Convert.ToInt32(ddlProdCategory.SelectedValue);
                int supId = Convert.ToInt32(ddlProdSupplier.SelectedValue);
                string unit = txtProdUnit.Text.Trim();
                decimal cost = 0;
                decimal.TryParse(txtProdCostPrice.Text, out cost);
                decimal sell = 0;
                decimal.TryParse(txtProdSellingPrice.Text, out sell);
                int stock = 0;
                int.TryParse(txtProdStock.Text, out stock);
                int minAlert = 10;
                int.TryParse(txtProdMinAlert.Text, out minAlert);
                string icon = string.IsNullOrEmpty(txtProdIcon.Text) ? "📦" : txtProdIcon.Text.Trim();

                if (string.IsNullOrEmpty(name))
                {
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Vui lòng nhập tên sản phẩm!', 'warning');", true);
                    return;
                }

                if (id == 0)
                {
                    string code = "SP" + DateTime.Now.ToString("yyyyMMdd") + new Random().Next(100, 999);
                    DatabaseHelper.AddProduct(
                        code, barcode, name,
                        catId > 0 ? (int?)catId : null,
                        supId > 0 ? (int?)supId : null,
                        unit, cost, sell, stock, minAlert, icon
                    );
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Thêm sản phẩm mới thành công!', 'success');", true);
                }
                else
                {
                    DatabaseHelper.UpdateProduct(
                        id, barcode, name,
                        catId > 0 ? (int?)catId : null,
                        supId > 0 ? (int?)supId : null,
                        unit, cost, sell, stock, minAlert, icon
                    );
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Cập nhật sản phẩm thành công!', 'success');", true);
                }

                LoadProducts();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }

        protected void btnDelete_Click(object sender, EventArgs e)
        {
            var btn = (LinkButton)sender;
            int id = Convert.ToInt32(btn.CommandArgument);
            try
            {
                DatabaseHelper.DeleteProduct(id);
                ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Đã xóa sản phẩm thành công!', 'success');", true);
                LoadProducts();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Không thể xóa sản phẩm: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }
    }
}
