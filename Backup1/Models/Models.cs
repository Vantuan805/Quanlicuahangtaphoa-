using System;
using System.Collections.Generic;

namespace QuanLiCuaHangTapHoa.Models
{
    public class Category
    {
        public int Id { get; set; }
        public string Code { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public int ProductCount { get; set; }
    }

    public class Supplier
    {
        public int Id { get; set; }
        public string Code { get; set; }
        public string Name { get; set; }
        public string Phone { get; set; }
        public string Email { get; set; }
        public string Address { get; set; }
        public string Notes { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class Customer
    {
        public int Id { get; set; }
        public string Code { get; set; }
        public string Name { get; set; }
        public string Phone { get; set; }
        public string Address { get; set; }
        public int Points { get; set; }
        public decimal TotalSpent { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class Employee
    {
        public int Id { get; set; }
        public string Code { get; set; }
        public string Name { get; set; }
        public string Phone { get; set; }
        public string Role { get; set; }
        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class Product
    {
        public int Id { get; set; }
        public string Code { get; set; }
        public string Barcode { get; set; }
        public string Name { get; set; }
        public int? CategoryId { get; set; }
        public string CategoryName { get; set; }
        public int? SupplierId { get; set; }
        public string SupplierName { get; set; }
        public string Unit { get; set; }
        public decimal CostPrice { get; set; }
        public decimal SellingPrice { get; set; }
        public int StockQuantity { get; set; }
        public int MinStockAlert { get; set; }
        public string ImageIcon { get; set; }
        public DateTime CreatedAt { get; set; }

        public decimal InventoryValue
        {
            get { return StockQuantity * CostPrice; }
        }

        public string StockStatus
        {
            get
            {
                if (StockQuantity <= 0) return "Hết hàng";
                if (StockQuantity <= MinStockAlert) return "Sắp hết";
                return "Còn hàng";
            }
        }

        public string StockBadgeClass
        {
            get
            {
                if (StockQuantity <= 0) return "badge-danger";
                if (StockQuantity <= MinStockAlert) return "badge-warning";
                return "badge-success";
            }
        }
    }

    public class Invoice
    {
        public int Id { get; set; }
        public string Code { get; set; }
        public int? CustomerId { get; set; }
        public string CustomerName { get; set; }
        public string CustomerPhone { get; set; }
        public string CustomerAddress { get; set; }
        public int? EmployeeId { get; set; }
        public string EmployeeName { get; set; }
        public decimal Subtotal { get; set; }
        public decimal Discount { get; set; }
        public decimal TotalAmount { get; set; }
        public decimal CustomerPayment { get; set; }
        public decimal ChangeAmount { get; set; }
        public string PaymentMethod { get; set; }
        public string Notes { get; set; }
        public DateTime InvoiceDate { get; set; }
        public DateTime CreatedAt { get; set; }
        public int ItemCount { get; set; }
        public List<InvoiceDetail> Items { get; set; }

        public Invoice()
        {
            Items = new List<InvoiceDetail>();
        }
    }

    public class InvoiceDetail
    {
        public int Id { get; set; }
        public int InvoiceId { get; set; }
        public int ProductId { get; set; }
        public string ProductName { get; set; }
        public string Unit { get; set; }
        public int Quantity { get; set; }
        public decimal CostPrice { get; set; }
        public decimal SellingPrice { get; set; }
        public decimal TotalPrice { get; set; }
    }

    public class GoodsReceipt
    {
        public int Id { get; set; }
        public string Code { get; set; }
        public int? SupplierId { get; set; }
        public string SupplierName { get; set; }
        public string SupplierPhone { get; set; }
        public string SupplierAddress { get; set; }
        public int? EmployeeId { get; set; }
        public string EmployeeName { get; set; }
        public decimal TotalAmount { get; set; }
        public string Notes { get; set; }
        public DateTime ReceiptDate { get; set; }
        public DateTime CreatedAt { get; set; }
        public int ItemCount { get; set; }
        public List<GoodsReceiptDetail> Items { get; set; }

        public GoodsReceipt()
        {
            Items = new List<GoodsReceiptDetail>();
        }
    }

    public class GoodsReceiptDetail
    {
        public int Id { get; set; }
        public int ReceiptId { get; set; }
        public int ProductId { get; set; }
        public string ProductCode { get; set; }
        public string ProductName { get; set; }
        public string Unit { get; set; }
        public int Quantity { get; set; }
        public decimal CostPrice { get; set; }
        public decimal TotalPrice { get; set; }
    }

    public class StockAdjustment
    {
        public int Id { get; set; }
        public string Code { get; set; }
        public int ProductId { get; set; }
        public string ProductCode { get; set; }
        public string ProductName { get; set; }
        public string Unit { get; set; }
        public int OldQuantity { get; set; }
        public int NewQuantity { get; set; }
        public int ChangeQuantity { get; set; }
        public string Reason { get; set; }
        public int? EmployeeId { get; set; }
        public string EmployeeName { get; set; }
        public DateTime AdjustedAt { get; set; }
    }

    public class CartItem
    {
        public int ProductId { get; set; }
        public string Code { get; set; }
        public string Name { get; set; }
        public string Unit { get; set; }
        public decimal SellingPrice { get; set; }
        public int Quantity { get; set; }
        public int StockQuantity { get; set; }
        public decimal TotalPrice
        {
            get { return Quantity * SellingPrice; }
        }
    }
}
