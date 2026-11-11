using System;
using System.Data;
using System.Text;
using System.Web.UI;
using QuanLiCuaHangTapHoa.DAL;

namespace QuanLiCuaHangTapHoa
{
    public partial class Default : Page
    {
        public string ChartDataJson = "[]";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadDashboard();
            }
        }

        private void LoadDashboard()
        {
            try
            {
                DataRow summary = DatabaseHelper.GetDashboardSummary();
                if (summary != null)
                {
                    decimal todayRev = Convert.ToDecimal(summary["TodayRevenue"]);
                    int todayOrders = Convert.ToInt32(summary["TodayOrders"]);
                    decimal monthRev = Convert.ToDecimal(summary["MonthRevenue"]);
                    decimal grossProfit = Convert.ToDecimal(summary["GrossProfit"]);
                    int soldCount = Convert.ToInt32(summary["SoldCount"]);
                    int soldToday = Convert.ToInt32(summary["SoldToday"]);
                    decimal invValue = Convert.ToDecimal(summary["InventoryValue"]);
                    int invUnits = Convert.ToInt32(summary["InventoryTotalUnits"]);
                    int totalOrders = Convert.ToInt32(summary["TotalOrders"]);
                    int totalCustomers = Convert.ToInt32(summary["TotalCustomers"]);
                    int lowStock = Convert.ToInt32(summary["LowStockCount"]);

                    litTodayRevenue.Text = string.Format("{0:N0} ₫", todayRev);
                    litTodayOrders.Text = string.Format("{0} đơn hôm nay", todayOrders);
                    litMonthRevenue.Text = string.Format("{0:N0} ₫", monthRev);
                    litGrossProfit.Text = string.Format("Lãi ước tính: {0:N0} ₫", grossProfit);
                    litSoldCount.Text = soldCount.ToString("N0");
                    litSoldToday.Text = string.Format("Hôm nay: {0} món", soldToday);
                    litInventoryValue.Text = string.Format("{0:N0} ₫", invValue);
                    litInventoryTotalUnits.Text = string.Format("Tổng tồn: {0:N0} món", invUnits);
                    litTotalOrders.Text = totalOrders.ToString();
                    litTotalCustomers.Text = totalCustomers.ToString();
                    litLowStock.Text = lowStock.ToString();
                }

                // Top Selling
                DataTable dtTop = DatabaseHelper.GetTopSellingProducts(5);
                rptTopSelling.DataSource = dtTop;
                rptTopSelling.DataBind();

                // Low Stock
                var lowStockList = DatabaseHelper.GetProducts(null, null, true);
                rptLowStock.DataSource = lowStockList;
                rptLowStock.DataBind();

                // Recent Invoices
                DataTable dtRecent = DatabaseHelper.GetRecentInvoices(5);
                rptRecentInvoices.DataSource = dtRecent;
                rptRecentInvoices.DataBind();

                // 7-day revenue chart json
                DataTable dtChart = DatabaseHelper.GetRevenueLast7Days();
                var sb = new StringBuilder();
                sb.Append("[");
                for (int i = 0; i < dtChart.Rows.Count; i++)
                {
                    DataRow r = dtChart.Rows[i];
                    string label = r["Label"].ToString();
                    decimal rev = Convert.ToDecimal(r["Revenue"]);
                    int orders = Convert.ToInt32(r["Orders"]);
                    sb.Append(string.Format("{{\"Label\":\"{0}\",\"Revenue\":{1},\"Orders\":{2}}}", label, rev, orders));
                    if (i < dtChart.Rows.Count - 1) sb.Append(",");
                }
                sb.Append("]");
                ChartDataJson = sb.ToString();
            }
            catch (Exception ex)
            {
                litTodayRevenue.Text = "Lỗi kết nối CSDL";
            }
        }
    }
}
