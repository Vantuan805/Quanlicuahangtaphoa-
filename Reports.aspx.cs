using System;
using System.Data;
using System.Web.UI;
using QuanLiCuaHangTapHoa.DAL;

namespace QuanLiCuaHangTapHoa
{
    public partial class Reports : Page
    {
        private decimal totalCategoryRevenue = 0;
        private decimal totalPaymentAmount = 0;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadReports();
            }
        }

        private void LoadReports()
        {
            try
            {
                // Category Sales
                DataTable dtCat = DatabaseHelper.GetCategorySalesReport();
                foreach (DataRow r in dtCat.Rows)
                {
                    totalCategoryRevenue += Convert.ToDecimal(r["Revenue"]);
                }
                rptCategorySales.DataSource = dtCat;
                rptCategorySales.DataBind();

                // Payment Methods
                DataTable dtPay = DatabaseHelper.GetPaymentMethodsReport();
                foreach (DataRow r in dtPay.Rows)
                {
                    totalPaymentAmount += Convert.ToDecimal(r["Total"]);
                }
                rptPaymentMethods.DataSource = dtPay;
                rptPaymentMethods.DataBind();

                // Top Products
                DataTable dtTop = DatabaseHelper.GetTop10ProductsReport();
                rptTopProducts.DataSource = dtTop;
                rptTopProducts.DataBind();
            }
            catch { }
        }

        public string GetPercent(object revObj)
        {
            if (totalCategoryRevenue <= 0) return "0";
            decimal rev = Convert.ToDecimal(revObj);
            decimal pct = (rev / totalCategoryRevenue) * 100;
            return pct.ToString("F1");
        }

        public string GetPaymentPercent(object totalObj)
        {
            if (totalPaymentAmount <= 0) return "0";
            decimal tot = Convert.ToDecimal(totalObj);
            decimal pct = (tot / totalPaymentAmount) * 100;
            return pct.ToString("F1");
        }

        public string GetMarginPercent(object profitObj, object revObj)
        {
            decimal rev = Convert.ToDecimal(revObj);
            if (rev <= 0) return "0";
            decimal profit = Convert.ToDecimal(profitObj);
            decimal pct = (profit / rev) * 100;
            return pct.ToString("F1");
        }
    }
}
