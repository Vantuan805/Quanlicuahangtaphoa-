using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using QuanLiCuaHangTapHoa.DAL;

namespace QuanLiCuaHangTapHoa
{
    public partial class Suppliers : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadSuppliers();
            }
        }

        private void LoadSuppliers()
        {
            try
            {
                var list = DatabaseHelper.GetSuppliers();
                litCount.Text = list.Count.ToString();
                rptSuppliers.DataSource = list;
                rptSuppliers.DataBind();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }

        protected void btnSaveSupplier_Click(object sender, EventArgs e)
        {
            try
            {
                int id = Convert.ToInt32(hfSupId.Value);
                string name = txtSupName.Text.Trim();
                string phone = txtSupPhone.Text.Trim();
                string email = txtSupEmail.Text.Trim();
                string address = txtSupAddress.Text.Trim();
                string notes = txtSupNotes.Text.Trim();

                if (string.IsNullOrEmpty(name))
                {
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Vui lòng nhập tên nhà cung cấp!', 'warning');", true);
                    return;
                }

                if (id == 0)
                {
                    string code = "NCC" + DateTime.Now.ToString("yyyyMMdd") + new Random().Next(10, 99);
                    DatabaseHelper.AddSupplier(code, name, phone, email, address, notes);
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Thêm nhà cung cấp thành công!', 'success');", true);
                }
                else
                {
                    DatabaseHelper.UpdateSupplier(id, name, phone, email, address, notes);
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Cập nhật NCC thành công!', 'success');", true);
                }

                LoadSuppliers();
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
                DatabaseHelper.DeleteSupplier(id);
                ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Đã xóa nhà cung cấp!', 'success');", true);
                LoadSuppliers();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi khi xóa NCC: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }
    }
}
