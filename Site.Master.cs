using System;
using System.Data;
using System.IO;
using System.Web.UI;
using QuanLiCuaHangTapHoa.DAL;

namespace QuanLiCuaHangTapHoa
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadHeaderBadges();
            }
        }

        private void LoadHeaderBadges()
        {
            try
            {
                DataRow summary = DatabaseHelper.GetDashboardSummary();
                if (summary != null)
                {
                    int lowCount = Convert.ToInt32(summary["LowStockCount"]);
                    litTopbarLowCount.Text = lowCount.ToString();

                    if (lowCount > 0)
                    {
                        litSidebarLowBadge.Text = string.Format("<span class=\"badge badge-danger badge-pill\">{0}</span>", lowCount);
                    }
                    else
                    {
                        litSidebarLowBadge.Text = "";
                    }
                }
            }
            catch
            {
                litTopbarLowCount.Text = "0";
                litSidebarLowBadge.Text = "";
            }
        }

        public string IsActive(string pageName)
        {
            string currentPage = Path.GetFileName(Request.PhysicalPath);
            if (string.Equals(currentPage, pageName, StringComparison.OrdinalIgnoreCase))
            {
                return "active";
            }
            return "";
        }
    }
}
