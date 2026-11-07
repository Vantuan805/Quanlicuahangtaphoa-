using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using QuanLiCuaHangTapHoa.DAL;

namespace QuanLiCuaHangTapHoa
{
    public partial class Categories : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadCategories();
            }
        }

        private void LoadCategories()
        {
            try
            {
                var list = DatabaseHelper.GetCategories();
                litCount.Text = list.Count.ToString();
                rptCategories.DataSource = list;
                rptCategories.DataBind();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }

        protected void btnSaveCategory_Click(object sender, EventArgs e)
        {
            try
            {
                int id = Convert.ToInt32(hfCatId.Value);
                string name = txtCatName.Text.Trim();
                string desc = txtCatDesc.Text.Trim();

                if (string.IsNullOrEmpty(name))
                {
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Vui lòng nhập tên loại sản phẩm!', 'warning');", true);
                    return;
                }

                if (id == 0)
                {
                    string code = "LSP" + DateTime.Now.ToString("yyyyMMdd") + new Random().Next(10, 99);
                    DatabaseHelper.AddCategory(code, name, desc);
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Thêm loại sản phẩm thành công!', 'success');", true);
                }
                else
                {
                    DatabaseHelper.UpdateCategory(id, name, desc);
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Cập nhật thành công!', 'success');", true);
                }

                LoadCategories();
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
                string error;
                if (DatabaseHelper.DeleteCategory(id, out error))
                {
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Đã xóa loại sản phẩm!', 'success');", true);
                    LoadCategories();
                }
                else
                {
                    ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('{0}', 'warning');", error.Replace("'", "\\'")), true);
                }
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }
    }
}
