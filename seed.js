const { db, initDatabase } = require('./database');

function seedDatabase(force = false) {
  initDatabase();

  const countCategories = db.prepare('SELECT COUNT(*) as count FROM categories').get().count;
  if (countCategories > 0 && !force) {
    console.log('Database already has data. Skipping seed.');
    return;
  }

  if (force) {
    db.exec(`
      DELETE FROM stock_adjustments;
      DELETE FROM invoice_details;
      DELETE FROM invoices;
      DELETE FROM goods_receipt_details;
      DELETE FROM goods_receipts;
      DELETE FROM products;
      DELETE FROM employees;
      DELETE FROM customers;
      DELETE FROM suppliers;
      DELETE FROM categories;
    `);
  }

  console.log('Seeding grocery database...');

  // 1. Thêm Loại sản phẩm
  const insertCat = db.prepare('INSERT INTO categories (code, name, description) VALUES (?, ?, ?)');
  const categories = [
    ['LSP01', 'Đồ uống & Nước giải khát', 'Nước ngọt, nước suối, bia, nước tăng lực'],
    ['LSP02', 'Mì & Thực phẩm ăn liền', 'Mì gói, phở, bún miến, cháo ăn liền, xúc xích'],
    ['LSP03', 'Gia vị & Nước chấm', 'Nước mắm, dầu ăn, hạt nêm, bột ngọt, tương ớt'],
    ['LSP04', 'Sữa & Chế phẩm sữa', 'Sữa tươi, sữa đặc, sữa chua, phô mai'],
    ['LSP05', 'Bánh kẹo & Snack', 'Bánh quy, kẹo, bim bim, bánh ngọt'],
    ['LSP06', 'Hóa phẩm & Tẩy rửa', 'Bột giặt, nước rửa chén, nước xả, lau sàn'],
    ['LSP07', 'Chăm sóc cá nhân', 'Dầu gội, sữa tắm, kem đánh răng, xà phòng'],
    ['LSP08', 'Gạo & Đồ khô', 'Gạo sạch, đường cát, các loại đậu, trứng gà vịt']
  ];
  for (const cat of categories) {
    insertCat.run(cat[0], cat[1], cat[2]);
  }

  // 2. Thêm Nhà cung cấp
  const insertSup = db.prepare('INSERT INTO suppliers (code, name, phone, email, address, notes) VALUES (?, ?, ?, ?, ?, ?)');
  const suppliers = [
    ['NCC01', 'Công ty CP Acecook Việt Nam', '02838154064', 'lienhe@acecookvietnam.com', 'KCN Tân Bình, Tây Thạnh, Tân Phú, TP.HCM', 'NCC mì tôm chính hãng'],
    ['NCC02', 'Công ty TNHH Suntory PepsiCo VN', '02838219468', 'sales@suntorypepsico.vn', 'Tầng 5 Sheraton Saigon, Q.1, TP.HCM', 'NCC nước ngọt, Sting, Aquafina'],
    ['NCC03', 'Công ty CP Sữa Việt Nam (Vinamilk)', '1900636979', 'vinamilk@vinamilk.com.vn', 'Số 10 Tân Trào, Tân Phú, Q.7, TP.HCM', 'NCC sữa chua, sữa tươi'],
    ['NCC04', 'Công ty TNHH Unilever Việt Nam', '02854135686', 'unilever@unilever.com.vn', '156 Nguyễn Lương Bằng, Q.7, TP.HCM', 'NCC OMO, Sunlight, Clear, P/S'],
    ['NCC05', 'Công ty CP Hàng tiêu dùng Masan', '02862563862', 'contact@masangroup.com', 'Mplaza Saigon, Lê Duẩn, Q.1, TP.HCM', 'NCC Chinsu, Nam Ngư, Omachi'],
    ['NCC06', 'Đại lý Gạo Sạch Miền Tây', '0908123456', 'gaomientay@gmail.com', '128 Quốc Lộ 1A, Tiền Giang', 'NCC gạo ST25, gạo thơm lài']
  ];
  for (const sup of suppliers) {
    insertSup.run(sup[0], sup[1], sup[2], sup[3], sup[4], sup[5]);
  }

  // 3. Thêm Nhân viên
  const insertEmp = db.prepare('INSERT INTO employees (code, name, phone, role, status) VALUES (?, ?, ?, ?, ?)');
  const employees = [
    ['NV01', 'Nguyễn Văn Quản', '0912345678', 'Quản lý', 'active'],
    ['NV02', 'Trần Thị Mai', '0987654321', 'Thu ngân', 'active'],
    ['NV03', 'Lê Hoàng Nam', '0903112233', 'Nhân viên kho', 'active']
  ];
  for (const emp of employees) {
    insertEmp.run(emp[0], emp[1], emp[2], emp[3], emp[4]);
  }

  // 4. Thêm Khách hàng
  const insertCus = db.prepare('INSERT INTO customers (code, name, phone, address, points, total_spent) VALUES (?, ?, ?, ?, ?, ?)');
  const customers = [
    ['KH01', 'Chị Nguyễn Thị Lan', '0909111222', 'Số 12 Đường Số 5, P.7, Gò Vấp', 125, 1250000],
    ['KH02', 'Anh Trần Minh Tuấn', '0918222333', 'Số 45 Lê Lợi, P. Bến Nghé, Q.1', 85, 850000],
    ['KH03', 'Cô Ba Hạnh', '0933444555', 'Hẻm 88 Nguyễn Trãi, P.3, Q.5', 210, 2100000],
    ['KH04', 'Bác Hoàng Năm', '0977888999', 'Số 15 Hoàng Hoa Thám, Bình Thạnh', 45, 450000]
  ];
  for (const cus of customers) {
    insertCus.run(cus[0], cus[1], cus[2], cus[3], cus[4], cus[5]);
  }

  // 5. Thêm Sản phẩm
  // [code, barcode, name, cat_id, sup_id, unit, cost, sell, stock, min_alert, icon]
  const insertProd = db.prepare(`
    INSERT INTO products (code, barcode, name, category_id, supplier_id, unit, cost_price, selling_price, stock_quantity, min_stock_alert, image_icon)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const products = [
    ['SP001', '8934563138164', 'Mì Hảo Hảo Tôm chua cay 75g', 2, 1, 'Gói', 3800, 4500, 150, 20, '🍜'],
    ['SP002', '8936079121785', 'Mì Omachi Sườn hầm ngũ quả 80g', 2, 5, 'Gói', 7500, 9000, 85, 15, '🍜'],
    ['SP003', '8935049500544', 'Nước ngọt Coca Cola 320ml', 1, 2, 'Lon', 8500, 10000, 48, 12, '🥤'],
    ['SP004', '8934588012111', 'Nước ngọt Pepsi lon 320ml', 1, 2, 'Lon', 8200, 10000, 42, 12, '🥤'],
    ['SP005', '8934588012222', 'Nước khoáng Aquafina 500ml', 1, 2, 'Chai', 4000, 5500, 60, 15, '💧'],
    ['SP006', '8934561240012', 'Nước mắm Nam Ngư Đệ Nhị 900ml', 3, 5, 'Chai', 22000, 28000, 24, 6, '🏺'],
    ['SP007', '8934673129871', 'Dầu ăn Tường An Cooking Oil 1L', 3, 5, 'Chai', 43000, 52000, 18, 5, '🛢️'],
    ['SP008', '8936079120021', 'Nước tương Chinsu Nấm Shiitake 330ml', 3, 5, 'Chai', 18000, 23000, 20, 5, '🏺'],
    ['SP009', '8934673554412', 'Hạt nêm Knorr Thịt thăn 400g', 3, 4, 'Gói', 31000, 38000, 16, 5, '🧂'],
    ['SP010', '8934673667789', 'Bột ngọt Ajinomoto 454g', 3, 5, 'Gói', 32000, 39000, 15, 5, '🧂'],
    ['SP011', '8934673889911', 'Sữa tươi Vinamilk có đường 180ml', 4, 3, 'Lốc (4)', 28000, 34000, 35, 8, '🥛'],
    ['SP012', '8934673998822', 'Sữa chua Vinamilk có đường 100g', 4, 3, 'Lốc (4)', 24000, 29000, 22, 6, '🍨'],
    ['SP013', '8936036010014', 'Bánh Chocopie Orion hộp 12 cái', 5, 1, 'Hộp', 48000, 58000, 12, 4, '🥧'],
    ['SP014', '8936036020025', 'Snack Oishi Tôm cay 40g', 5, 1, 'Gói', 5000, 6500, 45, 10, '🍿'],
    ['SP015', '8934868112233', 'Bột giặt OMO Matic Cửa trên 3kg', 6, 4, 'Túi', 175000, 210000, 8, 3, '🧺'],
    ['SP016', '8934868223344', 'Nước rửa chén Sunlight Chanh 750g', 6, 4, 'Chai', 23000, 29000, 19, 5, '🧴'],
    ['SP017', '8934868334455', 'Dầu gội Clear Bạc hà 650g', 7, 4, 'Chai', 155000, 185000, 9, 3, '🧴'],
    ['SP018', '8934868445566', 'Kem đánh răng P/S Bảo vệ 123 200g', 7, 4, 'Hộp', 26000, 33000, 25, 6, '🪥'],
    ['SP019', '8938501234567', 'Gạo thơm ST25 Ông Cua túi 5kg', 8, 6, 'Túi', 165000, 195000, 14, 5, '🌾'],
    ['SP020', '8938502345678', 'Trứng gà tươi Ba Huân (Hộp 10)', 8, 6, 'Hộp', 27000, 33000, 4, 10, '🥚'], // Sắp hết
    ['SP021', '8934588019999', 'Nước tăng lực Red Bull 250ml', 1, 2, 'Lon', 11500, 14000, 3, 15, '⚡'], // Sắp hết
    ['SP022', '8936079128888', 'Xúc xích tiệt trùng Vissan 4 cây', 2, 5, 'Gói', 16000, 20000, 5, 10, '🌭'], // Sắp hết
    ['SP023', '8934588033333', 'Bia Tiger lon 330ml', 1, 2, 'Lon', 16500, 19500, 72, 24, '🍺']
  ];

  for (const p of products) {
    insertProd.run(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10]);
  }

  // 6. Thêm Phiếu nhập hàng mẫu (Goods Receipts)
  const insertReceipt = db.prepare(`
    INSERT INTO goods_receipts (code, supplier_id, employee_id, total_amount, notes, receipt_date)
    VALUES (?, ?, ?, ?, ?, datetime('now', '-2 days'))
  `);
  const insertReceiptDetail = db.prepare(`
    INSERT INTO goods_receipt_details (receipt_id, product_id, quantity, cost_price, total_price)
    VALUES (?, ?, ?, ?, ?)
  `);

  const r1 = insertReceipt.run('PN20261103001', 1, 3, 570000, 'Nhập mì tôm và bánh kẹo');
  insertReceiptDetail.run(r1.lastInsertRowid, 1, 100, 3800, 380000);
  insertReceiptDetail.run(r1.lastInsertRowid, 14, 38, 5000, 190000);

  const r2 = insertReceipt.run('PN20261104001', 2, 3, 1269000, 'Nhập nước giải khát Pepsi, Aquafina, Tiger');
  insertReceiptDetail.run(r2.lastInsertRowid, 3, 48, 8500, 408000);
  insertReceiptDetail.run(r2.lastInsertRowid, 5, 50, 4000, 200000);
  insertReceiptDetail.run(r2.lastInsertRowid, 23, 40, 16500, 661000);

  // 7. Thêm Hóa đơn bán hàng mẫu (Invoices & Details)
  const insertInv = db.prepare(`
    INSERT INTO invoices (code, customer_id, employee_id, subtotal, discount, total_amount, customer_payment, change_amount, payment_method, notes, invoice_date)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const insertInvDetail = db.prepare(`
    INSERT INTO invoice_details (invoice_id, product_id, product_name, unit, quantity, cost_price, selling_price, total_price)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);

  // Hóa đơn 1 (Hôm nay)
  const inv1 = insertInv.run(
    'HD20261105001', 1, 2, 147500, 0, 147500, 150000, 2500, 'Tiền mặt', 'Khách mua dùng gia đình',
    new Date().toISOString().replace('T', ' ').substring(0, 19)
  );
  insertInvDetail.run(inv1.lastInsertRowid, 1, 'Mì Hảo Hảo Tôm chua cay 75g', 'Gói', 5, 3800, 4500, 22500);
  insertInvDetail.run(inv1.lastInsertRowid, 3, 'Nước ngọt Coca Cola 320ml', 'Lon', 3, 8500, 10000, 30000);
  insertInvDetail.run(inv1.lastInsertRowid, 7, 'Dầu ăn Tường An Cooking Oil 1L', 'Chai', 1, 43000, 52000, 52000);
  insertInvDetail.run(inv1.lastInsertRowid, 9, 'Hạt nêm Knorr Thịt thăn 400g', 'Gói', 1, 31000, 38000, 38000);
  insertInvDetail.run(inv1.lastInsertRowid, 21, 'Nước tăng lực Red Bull 250ml', 'Lon', 1, 11500, 14000, 14000);

  // Hóa đơn 2 (Hôm nay - Chuyển khoản QR)
  const inv2 = insertInv.run(
    'HD20261105002', 2, 2, 283000, 10000, 273000, 273000, 0, 'Chuyển khoản QR', 'Khách quen chiết khấu 10k',
    new Date().toISOString().replace('T', ' ').substring(0, 19)
  );
  insertInvDetail.run(inv2.lastInsertRowid, 19, 'Gạo thơm ST25 Ông Cua túi 5kg', 'Túi', 1, 165000, 195000, 195000);
  insertInvDetail.run(inv2.lastInsertRowid, 11, 'Sữa tươi Vinamilk có đường 180ml', 'Lốc (4)', 1, 28000, 34000, 34000);
  insertInvDetail.run(inv2.lastInsertRowid, 6, 'Nước mắm Nam Ngư Đệ Nhị 900ml', 'Chai', 1, 22000, 28000, 28000);
  insertInvDetail.run(inv2.lastInsertRowid, 16, 'Nước rửa chén Sunlight Chanh 750g', 'Chai', 1, 23000, 29000, 29000);

  // Hóa đơn 3 (Hôm qua)
  const inv3 = insertInv.run(
    'HD20261104001', 3, 2, 382000, 0, 382000, 400000, 18000, 'Tiền mặt', 'Cô Ba mua hàng tuần',
    new Date(Date.now() - 86400000).toISOString().replace('T', ' ').substring(0, 19)
  );
  insertInvDetail.run(inv3.lastInsertRowid, 15, 'Bột giặt OMO Matic Cửa trên 3kg', 'Túi', 1, 175000, 210000, 210000);
  insertInvDetail.run(inv3.lastInsertRowid, 17, 'Dầu gội Clear Bạc hà 650g', 'Chai', 1, 155000, 185000, 185000);
  insertInvDetail.run(inv3.lastInsertRowid, 1, 'Mì Hảo Hảo Tôm chua cay 75g', 'Gói', 10, 3800, 4500, 45000);

  // Hóa đơn 4 (2 ngày trước)
  const inv4 = insertInv.run(
    'HD20261103001', null, 2, 234000, 0, 234000, 250000, 16000, 'Tiền mặt', 'Khách vãng lai',
    new Date(Date.now() - 2 * 86400000).toISOString().replace('T', ' ').substring(0, 19)
  );
  insertInvDetail.run(inv4.lastInsertRowid, 23, 'Bia Tiger lon 330ml', 'Lon', 12, 16500, 19500, 234000);

  // Hóa đơn 5 (3 ngày trước)
  const inv5 = insertInv.run(
    'HD20261102001', 4, 2, 116000, 0, 116000, 120000, 4000, 'Tiền mặt', 'Bác Năm mua bánh sữa',
    new Date(Date.now() - 3 * 86400000).toISOString().replace('T', ' ').substring(0, 19)
  );
  insertInvDetail.run(inv5.lastInsertRowid, 13, 'Bánh Chocopie Orion hộp 12 cái', 'Hộp', 1, 48000, 58000, 58000);
  insertInvDetail.run(inv5.lastInsertRowid, 11, 'Sữa tươi Vinamilk có đường 180ml', 'Lốc (4)', 1, 28000, 34000, 34000);
  insertInvDetail.run(inv5.lastInsertRowid, 20, 'Trứng gà tươi Ba Huân (Hộp 10)', 'Hộp', 1, 27000, 33000, 33000);

  // 8. Thêm phiếu kiểm kê mẫu (Stock Adjustment)
  const insertAdj = db.prepare(`
    INSERT INTO stock_adjustments (code, product_id, old_quantity, new_quantity, change_quantity, reason, employee_id, adjusted_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now', '-1 days'))
  `);
  insertAdj.run('KK001', 20, 6, 4, -2, 'Vỡ 2 quả trong quá trình vận chuyển', 3);

  console.log('Seeding completed successfully!');
}

if (require.main === module) {
  seedDatabase(true);
}

module.exports = { seedDatabase };
