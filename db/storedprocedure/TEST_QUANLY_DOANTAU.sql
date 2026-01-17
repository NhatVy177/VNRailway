-- =============================================
-- TEST STORED PROCEDURES QUẢN LÝ ĐOÀN TÀU
-- Chạy từng test để kiểm tra stored procedures hoạt động đúng
-- =============================================

USE VNRAILWAY;
GO

PRINT '================================================';
PRINT 'TEST STORED PROCEDURES QUẢN LÝ ĐOÀN TÀU';
PRINT '================================================';
PRINT '';

-- =============================================
-- TEST 1: sp_GetDanhSachDoanTau
-- =============================================
PRINT '1. TEST sp_GetDanhSachDoanTau';
PRINT '   - Lấy tất cả đoàn tàu, trang 1, 10 bản ghi';
GO

DECLARE @SoKetQua INT, @ThongBao NVARCHAR(255), @ReturnCode INT;

EXEC @ReturnCode = sp_GetDanhSachDoanTau
    @LoaiTau = NULL,
    @TimKiem = NULL,
    @Trang = 1,
    @KichThuocTrang = 10,
    @SoKetQua = @SoKetQua OUTPUT,
    @ThongBao = @ThongBao OUTPUT;

PRINT '   Return Code: ' + CAST(@ReturnCode AS VARCHAR(10));
PRINT '   Số kết quả: ' + CAST(@SoKetQua AS VARCHAR(10));
PRINT '   Thông báo: ' + @ThongBao;
PRINT '';

-- =============================================
-- TEST 2: sp_GetDanhSachDoanTau với filter
-- =============================================
PRINT '2. TEST sp_GetDanhSachDoanTau với filter loại tàu S';
GO

DECLARE @SoKetQua INT, @ThongBao NVARCHAR(255), @ReturnCode INT;

EXEC @ReturnCode = sp_GetDanhSachDoanTau
    @LoaiTau = 'S',
    @TimKiem = NULL,
    @Trang = 1,
    @KichThuocTrang = 5,
    @SoKetQua = @SoKetQua OUTPUT,
    @ThongBao = @ThongBao OUTPUT;

PRINT '   Return Code: ' + CAST(@ReturnCode AS VARCHAR(10));
PRINT '   Số kết quả: ' + CAST(@SoKetQua AS VARCHAR(10));
PRINT '   Thông báo: ' + @ThongBao;
PRINT '';

-- =============================================
-- TEST 3: sp_ThemDoanTau (thêm đoàn tàu test)
-- =============================================
PRINT '3. TEST sp_ThemDoanTau';
PRINT '   - Thêm đoàn tàu TEST';

-- Xóa nếu đã tồn tại
DELETE FROM DOAN_TAU WHERE MaDoanTau = 'TEST';
GO

DECLARE @ThongBao NVARCHAR(255), @ReturnCode INT;

EXEC @ReturnCode = sp_ThemDoanTau
    @MaDoanTau = 'TEST',
    @TenTau = N'Tàu Test',
    @HangSX = N'Test Corporation',
    @NgVanHanh = '2020-01-01',
    @LoaiTau = 'T',
    @ThongBao = @ThongBao OUTPUT;

PRINT '   Return Code: ' + CAST(@ReturnCode AS VARCHAR(10));
PRINT '   Thông báo: ' + @ThongBao;
PRINT '';

-- =============================================
-- TEST 4: sp_CapNhatDoanTau
-- =============================================
PRINT '4. TEST sp_CapNhatDoanTau';
PRINT '   - Cập nhật đoàn tàu TEST';
GO

DECLARE @ThongBao NVARCHAR(255), @ReturnCode INT;

EXEC @ReturnCode = sp_CapNhatDoanTau
    @MaDoanTau = 'TEST',
    @TenTau = N'Tàu Test Đã Cập Nhật',
    @HangSX = NULL,
    @NgVanHanh = NULL,
    @LoaiTau = 'S',
    @ThongBao = @ThongBao OUTPUT;

PRINT '   Return Code: ' + CAST(@ReturnCode AS VARCHAR(10));
PRINT '   Thông báo: ' + @ThongBao;

-- Kiểm tra kết quả
SELECT * FROM DOAN_TAU WHERE MaDoanTau = 'TEST';
PRINT '';

-- =============================================
-- TEST 5: sp_GetLichSuChuyenTauDoanTau
-- =============================================
PRINT '5. TEST sp_GetLichSuChuyenTauDoanTau';
PRINT '   - Lấy lịch sử đoàn tàu D001';
GO

DECLARE @SoKetQua INT, @ThongBao NVARCHAR(255), @ReturnCode INT;

EXEC @ReturnCode = sp_GetLichSuChuyenTauDoanTau
    @MaDoanTau = 'D001',
    @TuNgay = NULL,
    @DenNgay = NULL,
    @Trang = 1,
    @KichThuocTrang = 5,
    @SoKetQua = @SoKetQua OUTPUT,
    @ThongBao = @ThongBao OUTPUT;

PRINT '   Return Code: ' + CAST(@ReturnCode AS VARCHAR(10));
PRINT '   Số kết quả: ' + CAST(@SoKetQua AS VARCHAR(10));
PRINT '   Thông báo: ' + @ThongBao;
PRINT '';

-- =============================================
-- Clean up
-- =============================================
PRINT '6. Dọn dẹp dữ liệu test';
DELETE FROM DOAN_TAU WHERE MaDoanTau = 'TEST';
PRINT '   ✓ Đã xóa đoàn tàu TEST';
PRINT '';

PRINT '================================================';
PRINT 'HOÀN TẤT TEST!';
PRINT '================================================';
GO
