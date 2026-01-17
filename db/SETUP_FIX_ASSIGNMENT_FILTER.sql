-- Fix stored procedure usp_LayDanhSachChuyenTauQuanLy
-- Sửa lỗi bộ lọc trạng thái không hoạt động

USE VNRAILWAY;
GO

-- Chạy lại stored procedure đã sửa
:r .\storedprocedure\usp_LayDanhSachChuyenTauQuanLy.sql
GO

-- Test với trạng thái
DECLARE @ThongBao NVARCHAR(200);

PRINT '===== TEST 1: Tất cả trạng thái (NULL) ====='
EXEC usp_LayDanhSachChuyenTauQuanLy
    @MaChuyenTau = NULL,
    @NgayKhoiHanhTu = NULL,
    @NgayKhoiHanhDen = NULL,
    @LoaiTau = NULL,
    @TrangThai = NULL,
    @ThongBao = @ThongBao OUTPUT;
PRINT @ThongBao;
GO

PRINT '===== TEST 2: Chỉ chuyến cần phân công ====='
DECLARE @ThongBao NVARCHAR(200);
EXEC usp_LayDanhSachChuyenTauQuanLy
    @MaChuyenTau = NULL,
    @NgayKhoiHanhTu = NULL,
    @NgayKhoiHanhDen = NULL,
    @LoaiTau = NULL,
    @TrangThai = N'Chưa đủ phân công',
    @ThongBao = @ThongBao OUTPUT;
PRINT @ThongBao;
GO

PRINT '===== TEST 3: Chỉ chuyến đã đủ phân công ====='
DECLARE @ThongBao NVARCHAR(200);
EXEC usp_LayDanhSachChuyenTauQuanLy
    @MaChuyenTau = NULL,
    @NgayKhoiHanhTu = NULL,
    @NgayKhoiHanhDen = NULL,
    @LoaiTau = NULL,
    @TrangThai = N'Đủ phân công',
    @ThongBao = @ThongBao OUTPUT;
PRINT @ThongBao;
GO

PRINT 'Fix hoàn tất!'
