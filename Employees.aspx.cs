using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using QuanLiCuaHangTapHoa.DAL;

namespace QuanLiCuaHangTapHoa
{
    public partial class Employees : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadEmployees();
            }
        }

        private void LoadEmployees()
        {
            try
            {
                var list = DatabaseHelper.GetEmployees();
                litCount.Text = list.Count.ToString();
                rptEmployees.DataSource = list;
                rptEmployees.DataBind();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }

        protected void btnSaveEmployee_Click(object sender, EventArgs e)
        {
            try
            {
                int id = Convert.ToInt32(hfEmpId.Value);
                string name = txtEmpName.Text.Trim();
                string phone = txtEmpPhone.Text.Trim();
                string role = ddlEmpRole.SelectedValue;
                string status = ddlEmpStatus.SelectedValue;

                if (string.IsNullOrEmpty(name))
                {
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Vui lòng nhập họ tên nhân viên!', 'warning');", true);
                    return;
                }

                if (id == 0)
                {
                    string code = "NV" + DateTime.Now.ToString("yyyyMMdd") + new Random().Next(10, 99);
                    DatabaseHelper.AddEmployee(code, name, phone, role, status);
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Thêm nhân viên thành công!', 'success');", true);
                }
                else
                {
                    DatabaseHelper.UpdateEmployee(id, name, phone, role, status);
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Cập nhật nhân viên thành công!', 'success');", true);
                }

                LoadEmployees();
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
                DatabaseHelper.DeleteEmployee(id);
                ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Đã xóa nhân viên!', 'success');", true);
                LoadEmployees();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi khi xóa nhân viên: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }
    }
}
