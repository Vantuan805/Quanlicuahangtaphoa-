@echo off
chcp 65001 > nul
echo ====================================================================
echo  🔄 KHỞI TẠO CƠ SỞ DỮ LIỆU CHUẨN TIẾNG VIỆT UNICODE
echo ====================================================================
echo.

"%~dp0App_Data\SeedDatabase.exe"

echo.
pause
