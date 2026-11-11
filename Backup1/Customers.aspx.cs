using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using QuanLiCuaHangTapHoa.DAL;

namespace QuanLiCuaHangTapHoa
{
    public partial class Customers : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadCustomers();
            }
        }

        private void LoadCustomers()
        {
            try
            {
                string search = txtSearch.Text.Trim();
                var list = DatabaseHelper.GetCustomers(string.IsNullOrEmpty(search) ? null : search);
                litCount.Text = list.Count.ToString();
                rptCustomers.DataSource = list;
                rptCustomers.DataBind();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            LoadCustomers();
        }

        protected void btnReset_Click(object sender, EventArgs e)
        {
            txtSearch.Text = "";
            LoadCustomers();
        }

        protected void btnSaveCustomer_Click(object sender, EventArgs e)
        {
            try
            {
                int id = Convert.ToInt32(hfCustId.Value);
                string name = txtCustName.Text.Trim();
                string phone = txtCustPhone.Text.Trim();
                string address = txtCustAddress.Text.Trim();

                if (string.IsNullOrEmpty(name) || string.IsNullOrEmpty(phone))
                {
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Vui lòng nhập tên và số điện thoại!', 'warning');", true);
                    return;
                }

                if (id == 0)
                {
                    string code = "KH" + DateTime.Now.ToString("yyyyMMdd") + new Random().Next(10, 99);
                    DatabaseHelper.AddCustomer(code, name, phone, address);
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Thêm khách hàng thành công!', 'success');", true);
                }
                else
                {
                    DatabaseHelper.UpdateCustomer(id, name, phone, address);
                    ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Cập nhật khách hàng thành công!', 'success');", true);
                }

                LoadCustomers();
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
                DatabaseHelper.DeleteCustomer(id);
                ClientScript.RegisterStartupScript(GetType(), "alert", "showToast('Đã xóa khách hàng!', 'success');", true);
                LoadCustomers();
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(GetType(), "alert", string.Format("showToast('Lỗi khi xóa: {0}', 'error');", ex.Message.Replace("'", "\\'")), true);
            }
        }
    }
}
