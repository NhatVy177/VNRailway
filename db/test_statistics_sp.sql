USE VNRAILWAY
GO

-- Test các stored procedures thống kê

PRINT '========== TEST REVENUE STATISTICS =========='

-- 1. sp_ThongKeDoanhThu
PRINT '1. Testing sp_ThongKeDoanhThu...'
EXEC sp_ThongKeDoanhThu 
    @NgayBatDau = '2025-01-01', 
    @NgayKetThuc = '2025-12-31', 
    @TieuChi = N'Tổng thể'
GO

-- 2. sp_ThongKeDoanhThuTheoThang
PRINT '2. Testing sp_ThongKeDoanhThuTheoThang...'
EXEC sp_ThongKeDoanhThuTheoThang 
    @ThangBatDau = 1, 
    @NamBatDau = 2025, 
    @ThangKetThuc = 12, 
    @NamKetThuc = 2025
GO

-- 3. sp_ThongKeChuyenTauTheoThang
PRINT '3. Testing sp_ThongKeChuyenTauTheoThang...'
EXEC sp_ThongKeChuyenTauTheoThang 
    @ThangBatDau = 1, 
    @NamBatDau = 2025, 
    @ThangKetThuc = 12, 
    @NamKetThuc = 2025,
    @MaTuyen = NULL
GO

-- 4. sp_ThongKeDoanhThuTheoTuyen
PRINT '4. Testing sp_ThongKeDoanhThuTheoTuyen...'
EXEC sp_ThongKeDoanhThuTheoTuyen 
    @NgayBatDau = '2025-01-01', 
    @NgayKetThuc = '2025-12-31'
GO

-- 5. sp_ThongKeDoanhThuTheoLoaiCho
PRINT '5. Testing sp_ThongKeDoanhThuTheoLoaiCho...'
EXEC sp_ThongKeDoanhThuTheoLoaiCho 
    @NgayBatDau = '2025-01-01', 
    @NgayKetThuc = '2025-12-31'
GO

-- 6. sp_GetDanhSachTuyenDuong
PRINT '6. Testing sp_GetDanhSachTuyenDuong...'
EXEC sp_GetDanhSachTuyenDuong
GO

PRINT '========== TEST EMPLOYEE STATISTICS =========='

-- 7. sp_ThongKeNhanVienTheoThang
PRINT '7. Testing sp_ThongKeNhanVienTheoThang...'
EXEC sp_ThongKeNhanVienTheoThang 
    @Thang = 11, 
    @Nam = 2025
GO

-- 8. sp_ThongKeChiTietNhanVien
PRINT '8. Testing sp_ThongKeChiTietNhanVien...'
EXEC sp_ThongKeChiTietNhanVien 
    @Thang = 11, 
    @Nam = 2025,
    @PageNumber = 1,
    @PageSize = 10
GO

-- 9. sp_ThongKeNhanVienTheoBoPhan
PRINT '9. Testing sp_ThongKeNhanVienTheoBoPhan...'
EXEC sp_ThongKeNhanVienTheoBoPhan 
    @Thang = 11, 
    @Nam = 2025
GO

-- 10. sp_ThongKeViPhamNhanVien
PRINT '10. Testing sp_ThongKeViPhamNhanVien...'
EXEC sp_ThongKeViPhamNhanVien 
    @Thang = 11, 
    @Nam = 2025,
    @NguongViPham = 3
GO

-- 11. sp_GetDanhSachLoaiCho
PRINT '11. Testing sp_GetDanhSachLoaiCho...'
EXEC sp_GetDanhSachLoaiCho
GO

PRINT '========== ALL TESTS COMPLETED =========='
