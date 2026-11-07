@echo off
chcp 65001 > nul
echo ====================================================================
echo  🏪 HỆ THỐNG QUẢN LÝ CỬA HÀNG TẠP HÓA (ASP.NET WEB FORMS)
echo ====================================================================
echo.
echo Đang khởi chạy IIS Express tại địa chỉ: http://localhost:8088/Default.aspx
echo Nhấn Ctrl+C để dừng server.
echo.

start http://localhost:8088/Default.aspx
"C:\Program Files\IIS Express\iisexpress.exe" /path:"%~dp0" /port:8088

pause
