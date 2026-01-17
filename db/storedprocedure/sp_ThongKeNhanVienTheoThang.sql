USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_ThongKeNhanVienTheoThang
-- Thống kê tổng hợp nhân viên trong tháng
-- =============================================
CREATE OR ALTER PROC sp_ThongKeNhanVienTheoThang
    @Thang INT,
    @Nam INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NgayBatDau DATE = DATEFROMPARTS(@Nam, @Thang, 1);
    DECLARE @NgayKetThuc DATE = EOMONTH(@NgayBatDau);

    -- Tổng số nhân viên
    DECLARE @TongNhanVien INT;
    SELECT @TongNhanVien = COUNT(*) FROM NHAN_VIEN;

    -- Số nhân viên có phân công trong tháng (đi làm)
    DECLARE @NhanVienDiLam INT;
    SELECT @NhanVienDiLam = COUNT(DISTINCT nv.MaNV)
    FROM NHAN_VIEN nv
    WHERE EXISTS (
        SELECT 1 
        FROM PHANCONG_LAITAU pclt
        JOIN CHUYEN_TAU ct ON pclt.MaChuyenTau = ct.MaChuyenTau
        WHERE pclt.MaNV = nv.MaNV
          AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
          AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
    )
    OR EXISTS (
        SELECT 1 
        FROM PHANCONG_TOA pct
        JOIN CHUYEN_TAU ct ON pct.MaChuyenTau = ct.MaChuyenTau
        WHERE pct.MaNV = nv.MaNV
          AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
          AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
    );

    -- Số nhân viên nghỉ phép
    DECLARE @NhanVienNghiPhep INT;
    SELECT @NhanVienNghiPhep = COUNT(DISTINCT nv.MaNV)
    FROM NHAN_VIEN nv
    WHERE EXISTS (
        SELECT 1 
        FROM PHANCONG_LAITAU pclt
        JOIN CHUYEN_TAU ct ON pclt.MaChuyenTau = ct.MaChuyenTau
        WHERE pclt.MaNV = nv.MaNV
          AND pclt.TrangThai = N'Nghỉ phép'
          AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
          AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
    )
    OR EXISTS (
        SELECT 1 
        FROM PHANCONG_TOA pct
        JOIN CHUYEN_TAU ct ON pct.MaChuyenTau = ct.MaChuyenTau
        WHERE pct.MaNV = nv.MaNV
          AND pct.TrangThai = N'Nghỉ phép'
          AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
          AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
    );

    -- Tỷ lệ vắng mặt
    DECLARE @TyLeVangMat DECIMAL(5, 2) = 0;
    IF @TongNhanVien > 0
        SET @TyLeVangMat = (@TongNhanVien - @NhanVienDiLam) * 100.0 / @TongNhanVien;

    SELECT 
        @TongNhanVien AS TongNhanVien,
        @NhanVienDiLam AS NhanVienDiLam,
        @NhanVienNghiPhep AS NhanVienNghiPhep,
        (@TongNhanVien - @NhanVienDiLam) AS NhanVienKhongPhanCong,
        @TyLeVangMat AS TyLeVangMat;
    
    RETURN 0;
END
GO
