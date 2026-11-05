const http = require('node:http');
const url = require('node:url');
const path = require('node:path');
const fs = require('node:fs');
const { db, initDatabase } = require('./db/database');
const { seedDatabase } = require('./db/seed');

// Khởi tạo CSDL nếu chưa có
initDatabase();
seedDatabase(false);

const PORT = process.env.PORT || 3000;
const PUBLIC_DIR = path.join(__dirname, 'public');

const MIME_TYPES = {
  '.html': 'text/html; charset=UTF-8',
  '.css': 'text/css; charset=UTF-8',
  '.js': 'application/javascript; charset=UTF-8',
  '.json': 'application/json; charset=UTF-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

// Helper gửi phản hồi JSON
function sendJSON(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=UTF-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  });
  res.end(JSON.stringify(data));
}

// Helper gửi lỗi
function sendError(res, statusCode, message) {
  sendJSON(res, statusCode, { success: false, error: message });
}

// Helper parse body JSON
function parseRequestBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk;
      if (body.length > 5 * 1024 * 1024) { // 5MB limit
        reject(new Error('Payload too large'));
      }
    });
    req.on('end', () => {
      if (!body.trim()) {
        resolve({});
        return;
      }
      try {
        const parsed = JSON.parse(body);
        resolve(parsed);
      } catch (err) {
        reject(new Error('Invalid JSON'));
      }
    });
    req.on('error', reject);
  });
}

// Helper sinh mã tự động
function generateCode(prefix) {
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const rand = Math.floor(1000 + Math.random() * 9000);
  return `${prefix}${dateStr}${rand}`;
}

// Router chính
const server = http.createServer(async (req, res) => {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    });
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const query = parsedUrl.query;
  const method = req.method.toUpperCase();

  try {
    // ----------------- API ROUTES -----------------

    // 1. DASHBOARD & THỐNG KÊ TỔNG HỢP
    if (pathname === '/api/dashboard' && method === 'GET') {
      // Doanh thu trong ngày
      const todayRevRow = db.prepare(`
        SELECT COALESCE(SUM(total_amount), 0) as revenue, COUNT(*) as order_count
        FROM invoices
        WHERE date(invoice_date) = date('now', 'localtime')
      `).get();

      // Doanh thu trong tháng
      const monthRevRow = db.prepare(`
        SELECT COALESCE(SUM(total_amount), 0) as revenue
        FROM invoices
        WHERE strftime('%Y-%m', invoice_date) = strftime('%Y-%m', 'now', 'localtime')
      `).get();

      // Tổng đơn hàng toàn thời gian
      const totalOrdersRow = db.prepare('SELECT COUNT(*) as count FROM invoices').get();

      // Tổng khách hàng
      const totalCustomersRow = db.prepare('SELECT COUNT(*) as count FROM customers').get();

      // Số lượng sản phẩm đã bán (toàn thời gian & hôm nay)
      const soldItemsRow = db.prepare('SELECT COALESCE(SUM(quantity), 0) as total FROM invoice_details').get();
      const soldItemsTodayRow = db.prepare(`
        SELECT COALESCE(SUM(d.quantity), 0) as total
        FROM invoice_details d
        JOIN invoices i ON d.invoice_id = i.id
        WHERE date(i.invoice_date) = date('now', 'localtime')
      `).get();

      // Tổng giá trị hàng tồn kho (giá trị vốn = số lượng tồn * giá nhập)
      const invValueRow = db.prepare('SELECT COALESCE(SUM(stock_quantity * cost_price), 0) as value, SUM(stock_quantity) as total_units FROM products').get();

      // Số lượng sản phẩm sắp hết hàng (tồn <= min_stock_alert)
      const lowStockRow = db.prepare('SELECT COUNT(*) as count FROM products WHERE stock_quantity <= min_stock_alert').get();

      // Danh sách sản phẩm sắp hết hàng
      const lowStockProducts = db.prepare(`
        SELECT p.*, c.name as category_name, s.name as supplier_name
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN suppliers s ON p.supplier_id = s.id
        WHERE p.stock_quantity <= p.min_stock_alert
        ORDER BY p.stock_quantity ASC
        LIMIT 10
      `).all();

      // Top 5 sản phẩm bán chạy nhất
      const topSelling = db.prepare(`
        SELECT d.product_id, d.product_name, d.unit, SUM(d.quantity) as total_sold, SUM(d.total_price) as total_revenue
        FROM invoice_details d
        GROUP BY d.product_id, d.product_name, d.unit
        ORDER BY total_sold DESC
        LIMIT 5
      `).all();

      // Doanh thu 7 ngày gần nhất
      const revenueLast7Days = db.prepare(`
        WITH RECURSIVE dates(d) AS (
          SELECT date('now', 'localtime', '-6 days')
          UNION ALL
          SELECT date(d, '+1 day') FROM dates WHERE d < date('now', 'localtime')
        )
        SELECT 
          dates.d as date,
          strftime('%d/%m', dates.d) as label,
          COALESCE(SUM(i.total_amount), 0) as revenue,
          COUNT(i.id) as orders
        FROM dates
        LEFT JOIN invoices i ON date(i.invoice_date) = dates.d
        GROUP BY dates.d
        ORDER BY dates.d ASC
      `).all();

      // Hóa đơn gần đây
      const recentInvoices = db.prepare(`
        SELECT i.*, c.name as customer_name, e.name as employee_name
        FROM invoices i
        LEFT JOIN customers c ON i.customer_id = c.id
        LEFT JOIN employees e ON i.employee_id = e.id
        ORDER BY i.id DESC
        LIMIT 5
      `).all();

      // Lợi nhuận gộp ước tính (Tổng Doanh thu - Tổng Giá vốn)
      const profitRow = db.prepare(`
        SELECT 
          COALESCE(SUM(d.total_price), 0) as total_sales,
          COALESCE(SUM(d.quantity * d.cost_price), 0) as total_cost,
          COALESCE(SUM(d.total_price - (d.quantity * d.cost_price)), 0) as gross_profit
        FROM invoice_details d
      `).get();

      return sendJSON(res, 200, {
        success: true,
        data: {
          todayRevenue: todayRevRow.revenue,
          todayOrders: todayRevRow.order_count,
          monthRevenue: monthRevRow.revenue,
          totalOrders: totalOrdersRow.count,
          totalCustomers: totalCustomersRow.count,
          soldProductsCount: soldItemsRow.total,
          soldProductsToday: soldItemsTodayRow.total,
          inventoryValue: invValueRow.value,
          inventoryTotalUnits: invValueRow.total_units || 0,
          lowStockCount: lowStockRow.count,
          grossProfit: profitRow.gross_profit,
          lowStockProducts,
          topSelling,
          revenueLast7Days,
          recentInvoices
        }
      });
    }

    // 2. LOẠI SẢN PHẨM (CATEGORIES)
    if (pathname === '/api/categories') {
      if (method === 'GET') {
        const rows = db.prepare(`
          SELECT c.*, COUNT(p.id) as product_count
          FROM categories c
          LEFT JOIN products p ON c.id = p.category_id
          GROUP BY c.id
          ORDER BY c.id ASC
        `).all();
        return sendJSON(res, 200, { success: true, data: rows });
      }

      if (method === 'POST') {
        const body = await parseRequestBody(req);
        if (!body.name) return sendError(res, 400, 'Tên loại sản phẩm là bắt buộc');
        const code = body.code || ('LSP' + String(Date.now()).slice(-4));
        const stmt = db.prepare('INSERT INTO categories (code, name, description) VALUES (?, ?, ?)');
        const result = stmt.run(code, body.name.trim(), body.description || '');
        return sendJSON(res, 201, { success: true, data: { id: result.lastInsertRowid, code, name: body.name } });
      }
    }

    const catMatch = pathname.match(/^\/api\/categories\/(\d+)$/);
    if (catMatch) {
      const id = parseInt(catMatch[1]);
      if (method === 'PUT') {
        const body = await parseRequestBody(req);
        if (!body.name) return sendError(res, 400, 'Tên loại sản phẩm là bắt buộc');
        db.prepare('UPDATE categories SET name = ?, description = ? WHERE id = ?')
          .run(body.name.trim(), body.description || '', id);
        return sendJSON(res, 200, { success: true, message: 'Cập nhật thành công' });
      }
      if (method === 'DELETE') {
        // Kiểm tra xem có sản phẩm thuộc loại này không
        const prods = db.prepare('SELECT COUNT(*) as count FROM products WHERE category_id = ?').get(id);
        if (prods.count > 0) {
          return sendError(res, 400, `Không thể xóa vì còn ${prods.count} sản phẩm thuộc loại này.`);
        }
        db.prepare('DELETE FROM categories WHERE id = ?').run(id);
        return sendJSON(res, 200, { success: true, message: 'Đã xóa loại sản phẩm' });
      }
    }

    // 3. NHÀ CUNG CẤP (SUPPLIERS)
    if (pathname === '/api/suppliers') {
      if (method === 'GET') {
        const rows = db.prepare('SELECT * FROM suppliers ORDER BY id DESC').all();
        return sendJSON(res, 200, { success: true, data: rows });
      }
      if (method === 'POST') {
        const body = await parseRequestBody(req);
        if (!body.name) return sendError(res, 400, 'Tên nhà cung cấp là bắt buộc');
        const code = body.code || ('NCC' + String(Date.now()).slice(-4));
        const stmt = db.prepare('INSERT INTO suppliers (code, name, phone, email, address, notes) VALUES (?, ?, ?, ?, ?, ?)');
        const result = stmt.run(code, body.name.trim(), body.phone || '', body.email || '', body.address || '', body.notes || '');
        return sendJSON(res, 201, { success: true, data: { id: result.lastInsertRowid, code } });
      }
    }

    const supMatch = pathname.match(/^\/api\/suppliers\/(\d+)$/);
    if (supMatch) {
      const id = parseInt(supMatch[1]);
      if (method === 'PUT') {
        const body = await parseRequestBody(req);
        if (!body.name) return sendError(res, 400, 'Tên nhà cung cấp là bắt buộc');
        db.prepare('UPDATE suppliers SET name = ?, phone = ?, email = ?, address = ?, notes = ? WHERE id = ?')
          .run(body.name.trim(), body.phone || '', body.email || '', body.address || '', body.notes || '', id);
        return sendJSON(res, 200, { success: true, message: 'Cập nhật thành công' });
      }
      if (method === 'DELETE') {
        db.prepare('DELETE FROM suppliers WHERE id = ?').run(id);
        return sendJSON(res, 200, { success: true, message: 'Đã xóa nhà cung cấp' });
      }
    }

    // 4. KHÁCH HÀNG (CUSTOMERS)
    if (pathname === '/api/customers') {
      if (method === 'GET') {
        const q = (query.q || '').trim();
        let rows;
        if (q) {
          rows = db.prepare(`
            SELECT * FROM customers 
            WHERE name LIKE ? OR phone LIKE ? OR code LIKE ?
            ORDER BY id DESC
          `).all(`%${q}%`, `%${q}%`, `%${q}%`);
        } else {
          rows = db.prepare('SELECT * FROM customers ORDER BY id DESC').all();
        }
        return sendJSON(res, 200, { success: true, data: rows });
      }
      if (method === 'POST') {
        const body = await parseRequestBody(req);
        if (!body.name) return sendError(res, 400, 'Tên khách hàng là bắt buộc');
        const code = body.code || ('KH' + String(Date.now()).slice(-4));
        const stmt = db.prepare('INSERT INTO customers (code, name, phone, address, points, total_spent) VALUES (?, ?, ?, ?, ?, ?)');
        const result = stmt.run(code, body.name.trim(), body.phone || '', body.address || '', body.points || 0, body.total_spent || 0);
        return sendJSON(res, 201, { success: true, data: { id: result.lastInsertRowid, code, name: body.name } });
      }
    }

    const cusMatch = pathname.match(/^\/api\/customers\/(\d+)$/);
    if (cusMatch) {
      const id = parseInt(cusMatch[1]);
      if (method === 'PUT') {
        const body = await parseRequestBody(req);
        if (!body.name) return sendError(res, 400, 'Tên khách hàng là bắt buộc');
        db.prepare('UPDATE customers SET name = ?, phone = ?, address = ?, points = ? WHERE id = ?')
          .run(body.name.trim(), body.phone || '', body.address || '', body.points || 0, id);
        return sendJSON(res, 200, { success: true, message: 'Cập nhật thành công' });
      }
      if (method === 'DELETE') {
        db.prepare('DELETE FROM customers WHERE id = ?').run(id);
        return sendJSON(res, 200, { success: true, message: 'Đã xóa khách hàng' });
      }
    }

    // 5. NHÂN VIÊN (EMPLOYEES)
    if (pathname === '/api/employees') {
      if (method === 'GET') {
        const rows = db.prepare('SELECT * FROM employees ORDER BY id ASC').all();
        return sendJSON(res, 200, { success: true, data: rows });
      }
      if (method === 'POST') {
        const body = await parseRequestBody(req);
        if (!body.name || !body.name.trim()) return sendError(res, 400, 'Họ và tên nhân viên là bắt buộc');
        
        let code = body.code ? body.code.trim().toUpperCase() : '';
        if (!code) {
          // Tự động sinh mã nhân viên tuần tự chuẩn: NV01, NV02, NV03 -> NV04, NV05...
          const lastEmp = db.prepare('SELECT code FROM employees WHERE code LIKE ? ORDER BY id DESC LIMIT 1').get('NV%');
          if (lastEmp && lastEmp.code) {
            const num = parseInt(lastEmp.code.replace(/\D/g, '')) || 0;
            code = 'NV' + String(num + 1).padStart(2, '0');
          } else {
            code = 'NV01';
          }
        }

        // Kiểm tra xem mã nhân viên đã trùng hay chưa
        const existing = db.prepare('SELECT id FROM employees WHERE code = ?').get(code);
        if (existing) {
          return sendError(res, 400, `Mã nhân viên "${code}" đã tồn tại. Vui lòng chọn mã khác.`);
        }

        const stmt = db.prepare('INSERT INTO employees (code, name, phone, role, status) VALUES (?, ?, ?, ?, ?)');
        const result = stmt.run(code, body.name.trim(), body.phone ? body.phone.trim() : '', body.role || 'Thu ngân', body.status || 'active');
        return sendJSON(res, 201, { success: true, data: { id: result.lastInsertRowid, code, name: body.name.trim() } });
      }
    }

    const empMatch = pathname.match(/^\/api\/employees\/(\d+)$/);
    if (empMatch) {
      const id = parseInt(empMatch[1]);
      if (method === 'PUT') {
        const body = await parseRequestBody(req);
        if (!body.name || !body.name.trim()) return sendError(res, 400, 'Họ và tên nhân viên là bắt buộc');
        const code = body.code ? body.code.trim().toUpperCase() : '';

        if (code) {
          const dup = db.prepare('SELECT id FROM employees WHERE code = ? AND id != ?').get(code, id);
          if (dup) {
            return sendError(res, 400, `Mã nhân viên "${code}" đã được sử dụng bởi nhân viên khác.`);
          }
          db.prepare('UPDATE employees SET code = ?, name = ?, phone = ?, role = ?, status = ? WHERE id = ?')
            .run(code, body.name.trim(), body.phone ? body.phone.trim() : '', body.role || 'Thu ngân', body.status || 'active', id);
        } else {
          db.prepare('UPDATE employees SET name = ?, phone = ?, role = ?, status = ? WHERE id = ?')
            .run(body.name.trim(), body.phone ? body.phone.trim() : '', body.role || 'Thu ngân', body.status || 'active', id);
        }
        return sendJSON(res, 200, { success: true, message: 'Cập nhật thành công' });
      }
      if (method === 'DELETE') {
        db.prepare('DELETE FROM employees WHERE id = ?').run(id);
        return sendJSON(res, 200, { success: true, message: 'Đã xóa nhân viên' });
      }
    }

    // 6. SẢN PHẨM (PRODUCTS)
    if (pathname === '/api/products') {
      if (method === 'GET') {
        const q = (query.q || '').trim().toLowerCase();
        const categoryId = query.category_id ? parseInt(query.category_id) : null;
        const lowStock = query.low_stock === 'true';

        let sql = `
          SELECT p.*, c.name as category_name, s.name as supplier_name
          FROM products p
          LEFT JOIN categories c ON p.category_id = c.id
          LEFT JOIN suppliers s ON p.supplier_id = s.id
          WHERE 1=1
        `;
        const params = [];

        if (q) {
          sql += ' AND (LOWER(p.name) LIKE ? OR LOWER(p.code) LIKE ? OR LOWER(COALESCE(p.barcode, "")) LIKE ?)';
          params.push(`%${q}%`, `%${q}%`, `%${q}%`);
        }
        if (categoryId) {
          sql += ' AND p.category_id = ?';
          params.push(categoryId);
        }
        if (lowStock) {
          sql += ' AND p.stock_quantity <= p.min_stock_alert';
        }

        sql += ' ORDER BY p.id DESC';
        const rows = db.prepare(sql).all(...params);
        return sendJSON(res, 200, { success: true, data: rows });
      }

      if (method === 'POST') {
        const body = await parseRequestBody(req);
        if (!body.name) return sendError(res, 400, 'Tên sản phẩm là bắt buộc');
        const code = body.code || ('SP' + String(Date.now()).slice(-4));
        const stmt = db.prepare(`
          INSERT INTO products (code, barcode, name, category_id, supplier_id, unit, cost_price, selling_price, stock_quantity, min_stock_alert, image_icon)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `);
        const result = stmt.run(
          code,
          body.barcode || '',
          body.name.trim(),
          body.category_id || null,
          body.supplier_id || null,
          body.unit || 'Cái',
          Number(body.cost_price) || 0,
          Number(body.selling_price) || 0,
          Number(body.stock_quantity) || 0,
          Number(body.min_stock_alert) || 10,
          body.image_icon || '📦'
        );
        return sendJSON(res, 201, { success: true, data: { id: result.lastInsertRowid, code } });
      }
    }

    const prodMatch = pathname.match(/^\/api\/products\/(\d+)$/);
    if (prodMatch) {
      const id = parseInt(prodMatch[1]);
      if (method === 'GET') {
        const item = db.prepare(`
          SELECT p.*, c.name as category_name, s.name as supplier_name
          FROM products p
          LEFT JOIN categories c ON p.category_id = c.id
          LEFT JOIN suppliers s ON p.supplier_id = s.id
          WHERE p.id = ?
        `).get(id);
        if (!item) return sendError(res, 404, 'Không tìm thấy sản phẩm');
        return sendJSON(res, 200, { success: true, data: item });
      }
      if (method === 'PUT') {
        const body = await parseRequestBody(req);
        if (!body.name) return sendError(res, 400, 'Tên sản phẩm là bắt buộc');
        db.prepare(`
          UPDATE products
          SET name = ?, barcode = ?, category_id = ?, supplier_id = ?, unit = ?,
              cost_price = ?, selling_price = ?, stock_quantity = ?, min_stock_alert = ?, image_icon = ?
          WHERE id = ?
        `).run(
          body.name.trim(),
          body.barcode || '',
          body.category_id || null,
          body.supplier_id || null,
          body.unit || 'Cái',
          Number(body.cost_price) || 0,
          Number(body.selling_price) || 0,
          Number(body.stock_quantity) || 0,
          Number(body.min_stock_alert) || 10,
          body.image_icon || '📦',
          id
        );
        return sendJSON(res, 200, { success: true, message: 'Cập nhật sản phẩm thành công' });
      }
      if (method === 'DELETE') {
        db.prepare('DELETE FROM products WHERE id = ?').run(id);
        return sendJSON(res, 200, { success: true, message: 'Đã xóa sản phẩm' });
      }
    }

    // 7. BÁN HÀNG & HÓA ĐƠN (POS & INVOICES)
    if (pathname === '/api/invoices') {
      if (method === 'GET') {
        const q = (query.q || '').trim();
        const dateFrom = query.from || '';
        const dateTo = query.to || '';

        let sql = `
          SELECT i.*, c.name as customer_name, c.phone as customer_phone, e.name as employee_name,
                 (SELECT COUNT(*) FROM invoice_details d WHERE d.invoice_id = i.id) as item_count
          FROM invoices i
          LEFT JOIN customers c ON i.customer_id = c.id
          LEFT JOIN employees e ON i.employee_id = e.id
          WHERE 1=1
        `;
        const params = [];
        if (q) {
          sql += ' AND (i.code LIKE ? OR c.name LIKE ? OR c.phone LIKE ?)';
          params.push(`%${q}%`, `%${q}%`, `%${q}%`);
        }
        if (dateFrom) {
          sql += ' AND date(i.invoice_date) >= date(?)';
          params.push(dateFrom);
        }
        if (dateTo) {
          sql += ' AND date(i.invoice_date) <= date(?)';
          params.push(dateTo);
        }
        sql += ' ORDER BY i.id DESC';
        const rows = db.prepare(sql).all(...params);
        return sendJSON(res, 200, { success: true, data: rows });
      }

      if (method === 'POST') {
        const body = await parseRequestBody(req);
        const { customer_id, employee_id, items, discount = 0, customer_payment = 0, payment_method = 'Tiền mặt', notes = '' } = body;

        if (!items || !Array.isArray(items) || items.length === 0) {
          return sendError(res, 400, 'Giỏ hàng đang trống, không thể thanh toán.');
        }

        // Bắt đầu transaction
        db.exec('BEGIN TRANSACTION;');
        try {
          // Kiểm tra tồn kho trước
          for (const item of items) {
            const prod = db.prepare('SELECT * FROM products WHERE id = ?').get(item.product_id);
            if (!prod) {
              throw new Error(`Sản phẩm #${item.product_id} không tồn tại.`);
            }
            if (prod.stock_quantity < item.quantity) {
              throw new Error(`Sản phẩm "${prod.name}" chỉ còn ${prod.stock_quantity} ${prod.unit} trong kho, không đủ bán!`);
            }
          }

          // Tính tổng tiền
          let subtotal = 0;
          for (const item of items) {
            subtotal += item.quantity * item.selling_price;
          }
          const totalAmount = Math.max(0, subtotal - Number(discount));
          const changeAmount = Math.max(0, Number(customer_payment) - totalAmount);
          const invoiceCode = generateCode('HD');

          // Lưu hóa đơn
          const insertInvStmt = db.prepare(`
            INSERT INTO invoices (code, customer_id, employee_id, subtotal, discount, total_amount, customer_payment, change_amount, payment_method, notes, invoice_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now', 'localtime'))
          `);
          const invRes = insertInvStmt.run(
            invoiceCode,
            customer_id || null,
            employee_id || null,
            subtotal,
            Number(discount),
            totalAmount,
            Number(customer_payment),
            changeAmount,
            payment_method,
            notes
          );
          const invoiceId = invRes.lastInsertRowid;

          // Thêm chi tiết & Trừ tồn kho
          const insertDetailStmt = db.prepare(`
            INSERT INTO invoice_details (invoice_id, product_id, product_name, unit, quantity, cost_price, selling_price, total_price)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          `);
          const updateStockStmt = db.prepare(`
            UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?
          `);

          for (const item of items) {
            const prod = db.prepare('SELECT * FROM products WHERE id = ?').get(item.product_id);
            const lineTotal = item.quantity * item.selling_price;
            insertDetailStmt.run(
              invoiceId,
              item.product_id,
              prod.name,
              prod.unit,
              item.quantity,
              prod.cost_price,
              item.selling_price,
              lineTotal
            );
            updateStockStmt.run(item.quantity, item.product_id);
          }

          // Cập nhật điểm & tổng chi tiêu khách hàng nếu có
          if (customer_id) {
            const addedPoints = Math.floor(totalAmount / 10000); // 10k = 1 điểm
            db.prepare(`
              UPDATE customers 
              SET points = points + ?, total_spent = total_spent + ?
              WHERE id = ?
            `).run(addedPoints, totalAmount, customer_id);
          }

          db.exec('COMMIT;');

          // Lấy lại đầy đủ thông tin hóa đơn vừa tạo
          const fullInvoice = db.prepare(`
            SELECT i.*, c.name as customer_name, c.phone as customer_phone, e.name as employee_name
            FROM invoices i
            LEFT JOIN customers c ON i.customer_id = c.id
            LEFT JOIN employees e ON i.employee_id = e.id
            WHERE i.id = ?
          `).get(invoiceId);

          const fullDetails = db.prepare('SELECT * FROM invoice_details WHERE invoice_id = ?').all(invoiceId);

          return sendJSON(res, 201, {
            success: true,
            data: {
              ...fullInvoice,
              items: fullDetails
            }
          });
        } catch (err) {
          db.exec('ROLLBACK;');
          return sendError(res, 400, err.message || 'Lỗi khi thanh toán hóa đơn');
        }
      }
    }

    // Chi tiết hóa đơn
    const invMatch = pathname.match(/^\/api\/invoices\/(\d+)$/);
    if (invMatch && method === 'GET') {
      const id = parseInt(invMatch[1]);
      const invoice = db.prepare(`
        SELECT i.*, c.name as customer_name, c.phone as customer_phone, c.address as customer_address, e.name as employee_name
        FROM invoices i
        LEFT JOIN customers c ON i.customer_id = c.id
        LEFT JOIN employees e ON i.employee_id = e.id
        WHERE i.id = ?
      `).get(id);

      if (!invoice) return sendError(res, 404, 'Không tìm thấy hóa đơn');
      const items = db.prepare('SELECT * FROM invoice_details WHERE invoice_id = ?').all(id);
      return sendJSON(res, 200, { success: true, data: { ...invoice, items } });
    }

    // 8. PHIẾU NHẬP HÀNG (GOODS RECEIPTS)
    if (pathname === '/api/receipts') {
      if (method === 'GET') {
        const rows = db.prepare(`
          SELECT r.*, s.name as supplier_name, e.name as employee_name,
                 (SELECT COUNT(*) FROM goods_receipt_details d WHERE d.receipt_id = r.id) as item_count
          FROM goods_receipts r
          LEFT JOIN suppliers s ON r.supplier_id = s.id
          LEFT JOIN employees e ON r.employee_id = e.id
          ORDER BY r.id DESC
        `).all();
        return sendJSON(res, 200, { success: true, data: rows });
      }

      if (method === 'POST') {
        const body = await parseRequestBody(req);
        const { supplier_id, employee_id, items, notes = '' } = body;

        if (!supplier_id) return sendError(res, 400, 'Vui lòng chọn Nhà cung cấp');
        if (!items || !Array.isArray(items) || items.length === 0) {
          return sendError(res, 400, 'Phiếu nhập cần có ít nhất 1 sản phẩm');
        }

        db.exec('BEGIN TRANSACTION;');
        try {
          let totalAmount = 0;
          for (const item of items) {
            totalAmount += Number(item.quantity) * Number(item.cost_price);
          }

          const receiptCode = generateCode('PN');
          const insertRecStmt = db.prepare(`
            INSERT INTO goods_receipts (code, supplier_id, employee_id, total_amount, notes, receipt_date)
            VALUES (?, ?, ?, ?, ?, datetime('now', 'localtime'))
          `);
          const recRes = insertRecStmt.run(receiptCode, supplier_id, employee_id || null, totalAmount, notes);
          const receiptId = recRes.lastInsertRowid;

          const insertDetailStmt = db.prepare(`
            INSERT INTO goods_receipt_details (receipt_id, product_id, quantity, cost_price, total_price)
            VALUES (?, ?, ?, ?, ?)
          `);
          const updateProdStmt = db.prepare(`
            UPDATE products 
            SET stock_quantity = stock_quantity + ?, cost_price = ?
            WHERE id = ?
          `);

          for (const item of items) {
            const lineTotal = Number(item.quantity) * Number(item.cost_price);
            insertDetailStmt.run(receiptId, item.product_id, item.quantity, item.cost_price, lineTotal);
            // Cộng kho và cập nhật giá nhập mới nhất
            updateProdStmt.run(item.quantity, item.cost_price, item.product_id);
          }

          db.exec('COMMIT;');
          return sendJSON(res, 201, { success: true, data: { id: receiptId, code: receiptCode, totalAmount } });
        } catch (err) {
          db.exec('ROLLBACK;');
          return sendError(res, 400, err.message || 'Lỗi khi tạo phiếu nhập hàng');
        }
      }
    }

    const recMatch = pathname.match(/^\/api\/receipts\/(\d+)$/);
    if (recMatch && method === 'GET') {
      const id = parseInt(recMatch[1]);
      const receipt = db.prepare(`
        SELECT r.*, s.name as supplier_name, s.phone as supplier_phone, s.address as supplier_address, e.name as employee_name
        FROM goods_receipts r
        LEFT JOIN suppliers s ON r.supplier_id = s.id
        LEFT JOIN employees e ON r.employee_id = e.id
        WHERE r.id = ?
      `).get(id);

      if (!receipt) return sendError(res, 404, 'Không tìm thấy phiếu nhập');
      const items = db.prepare(`
        SELECT d.*, p.name as product_name, p.code as product_code, p.unit
        FROM goods_receipt_details d
        JOIN products p ON d.product_id = p.id
        WHERE d.receipt_id = ?
      `).all(id);
      return sendJSON(res, 200, { success: true, data: { ...receipt, items } });
    }

    // 9. KHO HÀNG & KIỂM KÊ (INVENTORY & ADJUSTMENTS)
    if (pathname === '/api/inventory' && method === 'GET') {
      const q = (query.q || '').trim();
      const status = query.status || 'all'; // all, low, out, normal

      let sql = `
        SELECT p.*, c.name as category_name, s.name as supplier_name,
               (p.stock_quantity * p.cost_price) as inventory_value,
               CASE 
                 WHEN p.stock_quantity <= 0 THEN 'Hết hàng'
                 WHEN p.stock_quantity <= p.min_stock_alert THEN 'Sắp hết'
                 ELSE 'Còn hàng'
               END as stock_status
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN suppliers s ON p.supplier_id = s.id
        WHERE 1=1
      `;
      const params = [];
      if (q) {
        sql += ' AND (p.name LIKE ? OR p.code LIKE ?)';
        params.push(`%${q}%`, `%${q}%`);
      }
      if (status === 'low') {
        sql += ' AND p.stock_quantity > 0 AND p.stock_quantity <= p.min_stock_alert';
      } else if (status === 'out') {
        sql += ' AND p.stock_quantity <= 0';
      } else if (status === 'normal') {
        sql += ' AND p.stock_quantity > p.min_stock_alert';
      }
      sql += ' ORDER BY p.stock_quantity ASC';

      const rows = db.prepare(sql).all(...params);
      const summary = db.prepare(`
        SELECT 
          COUNT(*) as total_products,
          COALESCE(SUM(stock_quantity), 0) as total_units,
          COALESCE(SUM(stock_quantity * cost_price), 0) as total_value,
          SUM(CASE WHEN stock_quantity <= min_stock_alert AND stock_quantity > 0 THEN 1 ELSE 0 END) as low_count,
          SUM(CASE WHEN stock_quantity <= 0 THEN 1 ELSE 0 END) as out_count
        FROM products
      `).get();

      return sendJSON(res, 200, { success: true, data: { rows, summary } });
    }

    if (pathname === '/api/inventory/adjust' && method === 'POST') {
      const body = await parseRequestBody(req);
      const { product_id, new_quantity, reason = 'Kiểm kê định kỳ', employee_id } = body;

      if (!product_id || new_quantity === undefined) {
        return sendError(res, 400, 'Thiếu thông tin điều chỉnh kho');
      }

      const prod = db.prepare('SELECT * FROM products WHERE id = ?').get(product_id);
      if (!prod) return sendError(res, 404, 'Sản phẩm không tồn tại');

      const oldQuantity = prod.stock_quantity;
      const newQty = Math.max(0, parseInt(new_quantity));
      const diff = newQty - oldQuantity;
      const code = generateCode('KK');

      db.exec('BEGIN TRANSACTION;');
      try {
        db.prepare('UPDATE products SET stock_quantity = ? WHERE id = ?').run(newQty, product_id);
        db.prepare(`
          INSERT INTO stock_adjustments (code, product_id, old_quantity, new_quantity, change_quantity, reason, employee_id, adjusted_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now', 'localtime'))
        `).run(code, product_id, oldQuantity, newQty, diff, reason, employee_id || null);

        db.exec('COMMIT;');
        return sendJSON(res, 200, { success: true, message: 'Đã điều chỉnh số lượng tồn kho', data: { oldQuantity, newQuantity: newQty, diff } });
      } catch (err) {
        db.exec('ROLLBACK;');
        return sendError(res, 500, err.message);
      }
    }

    if (pathname === '/api/inventory/adjustments' && method === 'GET') {
      const rows = db.prepare(`
        SELECT a.*, p.name as product_name, p.code as product_code, p.unit, e.name as employee_name
        FROM stock_adjustments a
        JOIN products p ON a.product_id = p.id
        LEFT JOIN employees e ON a.employee_id = e.id
        ORDER BY a.id DESC
        LIMIT 50
      `).all();
      return sendJSON(res, 200, { success: true, data: rows });
    }

    // 10. BÁO CÁO CHI TIẾT (ADVANCED REPORTS)
    if (pathname === '/api/reports' && method === 'GET') {
      const period = query.period || '7days'; // 7days, 30days, year

      // Báo cáo doanh thu & lợi nhuận theo danh mục
      const categorySales = db.prepare(`
        SELECT c.id, c.name, 
               COALESCE(SUM(d.total_price), 0) as revenue,
               COALESCE(SUM(d.quantity), 0) as units_sold
        FROM categories c
        LEFT JOIN products p ON p.category_id = c.id
        LEFT JOIN invoice_details d ON d.product_id = p.id
        GROUP BY c.id, c.name
        ORDER BY revenue DESC
      `).all();

      // Top 10 sản phẩm bán chạy nhất
      const topProducts = db.prepare(`
        SELECT p.id, p.name, p.code, p.unit, p.image_icon,
               COALESCE(SUM(d.quantity), 0) as total_sold,
               COALESCE(SUM(d.total_price), 0) as total_revenue,
               COALESCE(SUM(d.total_price - (d.quantity * d.cost_price)), 0) as total_profit
        FROM products p
        JOIN invoice_details d ON p.id = d.product_id
        GROUP BY p.id, p.name, p.code, p.unit, p.image_icon
        ORDER BY total_sold DESC
        LIMIT 10
      `).all();

      // Doanh thu theo phương thức thanh toán
      const paymentMethods = db.prepare(`
        SELECT payment_method, COUNT(*) as count, SUM(total_amount) as total
        FROM invoices
        GROUP BY payment_method
      `).all();

      return sendJSON(res, 200, {
        success: true,
        data: {
          categorySales,
          topProducts,
          paymentMethods
        }
      });
    }

    // ----------------- STATIC FILES SERVING -----------------
    let filePath = pathname === '/' ? path.join(PUBLIC_DIR, 'index.html') : path.join(PUBLIC_DIR, pathname);

    // Chuẩn hóa path bảo mật tránh directory traversal
    const safePath = path.normalize(filePath);
    if (!safePath.startsWith(PUBLIC_DIR)) {
      res.writeHead(403, { 'Content-Type': 'text/plain; charset=UTF-8' });
      res.end('403 Forbidden');
      return;
    }

    fs.stat(safePath, (err, stats) => {
      if (err || !stats.isFile()) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=UTF-8' });
        res.end('404 Not Found');
        return;
      }

      const ext = path.extname(safePath).toLowerCase();
      const contentType = MIME_TYPES[ext] || 'application/octet-stream';

      res.writeHead(200, { 'Content-Type': contentType });
      const stream = fs.createReadStream(safePath);
      stream.pipe(res);
    });

  } catch (error) {
    console.error('Server error:', error);
    sendError(res, 500, error.message || 'Lỗi máy chủ nội bộ');
  }
});

server.listen(PORT, () => {
  console.log(`Grocery Store Management Server running at: http://localhost:${PORT}`);
});
