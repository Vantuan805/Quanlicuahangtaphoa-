const { DatabaseSync } = require('node:sqlite');
const path = require('node:path');
const fs = require('node:fs');

const dbPath = path.join(__dirname, 'grocery.sqlite');
const db = new DatabaseSync(dbPath);

// Kích hoạt foreign key
db.exec('PRAGMA foreign_keys = ON;');
db.exec('PRAGMA journal_mode = WAL;');

function initDatabase() {
  db.exec(`
    -- Bảng Loại sản phẩm
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );

    -- Bảng Nhà cung cấp
    CREATE TABLE IF NOT EXISTS suppliers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      phone TEXT,
      email TEXT,
      address TEXT,
      notes TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );

    -- Bảng Khách hàng
    CREATE TABLE IF NOT EXISTS customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      points INTEGER DEFAULT 0,
      total_spent REAL DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );

    -- Bảng Nhân viên
    CREATE TABLE IF NOT EXISTS employees (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      phone TEXT,
      role TEXT NOT NULL DEFAULT 'Thu ngân',
      status TEXT NOT NULL DEFAULT 'active',
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );

    -- Bảng Sản phẩm
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT UNIQUE NOT NULL,
      barcode TEXT,
      name TEXT NOT NULL,
      category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
      supplier_id INTEGER REFERENCES suppliers(id) ON DELETE SET NULL,
      unit TEXT NOT NULL DEFAULT 'Cái',
      cost_price REAL NOT NULL DEFAULT 0,
      selling_price REAL NOT NULL DEFAULT 0,
      stock_quantity INTEGER NOT NULL DEFAULT 0,
      min_stock_alert INTEGER NOT NULL DEFAULT 10,
      image_icon TEXT DEFAULT '📦',
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );

    -- Bảng Phiếu nhập hàng
    CREATE TABLE IF NOT EXISTS goods_receipts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT UNIQUE NOT NULL,
      supplier_id INTEGER REFERENCES suppliers(id) ON DELETE RESTRICT,
      employee_id INTEGER REFERENCES employees(id) ON DELETE SET NULL,
      total_amount REAL NOT NULL DEFAULT 0,
      notes TEXT,
      receipt_date TEXT DEFAULT (datetime('now', 'localtime')),
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );

    -- Chi tiết phiếu nhập hàng
    CREATE TABLE IF NOT EXISTS goods_receipt_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      receipt_id INTEGER NOT NULL REFERENCES goods_receipts(id) ON DELETE CASCADE,
      product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
      quantity INTEGER NOT NULL,
      cost_price REAL NOT NULL,
      total_price REAL NOT NULL
    );

    -- Bảng Hóa đơn bán hàng
    CREATE TABLE IF NOT EXISTS invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT UNIQUE NOT NULL,
      customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,
      employee_id INTEGER REFERENCES employees(id) ON DELETE SET NULL,
      subtotal REAL NOT NULL DEFAULT 0,
      discount REAL NOT NULL DEFAULT 0,
      total_amount REAL NOT NULL DEFAULT 0,
      customer_payment REAL NOT NULL DEFAULT 0,
      change_amount REAL NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL DEFAULT 'Tiền mặt',
      notes TEXT,
      invoice_date TEXT DEFAULT (datetime('now', 'localtime')),
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );

    -- Chi tiết hóa đơn
    CREATE TABLE IF NOT EXISTS invoice_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
      product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
      product_name TEXT NOT NULL,
      unit TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      cost_price REAL NOT NULL DEFAULT 0,
      selling_price REAL NOT NULL,
      total_price REAL NOT NULL
    );

    -- Lịch sử kiểm kê / điều chỉnh kho
    CREATE TABLE IF NOT EXISTS stock_adjustments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT UNIQUE NOT NULL,
      product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
      old_quantity INTEGER NOT NULL,
      new_quantity INTEGER NOT NULL,
      change_quantity INTEGER NOT NULL,
      reason TEXT,
      employee_id INTEGER REFERENCES employees(id) ON DELETE SET NULL,
      adjusted_at TEXT DEFAULT (datetime('now', 'localtime'))
    );
  `);
}

module.exports = {
  db,
  initDatabase
};
