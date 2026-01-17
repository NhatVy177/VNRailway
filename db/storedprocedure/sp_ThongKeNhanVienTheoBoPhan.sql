USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_ThongKeNhanVienTheoBoPhan
-- Thống kê số giờ làm việc theo bộ phận
-- =============================================
CREATE OR ALTER PROC sp_ThongKeNhanVienTheoBoPhan
    @Thang INT,
    @Nam INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NgayBatDau DATE = DATEFROMPARTS(@Nam, @Thang, 1);
    DECLARE @NgayKetThuc DATE = EOMONTH(@NgayBatDau);

    ;WITH NhanVienGioLamViec AS (
        SELECT 
            nv.ChucVu,
            nv.MaNV,
            ISNULL((
                SELECT SUM(DATEDIFF(MINUTE, ct.ThoiGianXuatPhat, ct.ThoiGianDuKienDen) / 60.0)
                FROM PHANCONG_LAITAU pclt
                JOIN CHUYEN_TAU ct ON pclt.MaChuyenTau = ct.MaChuyenTau
                WHERE pclt.MaNV = nv.MaNV
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
                  AND pclt.TrangThai <> N'Nghỉ phép'
            ), 0) +
            ISNULL((
                SELECT SUM(DATEDIFF(MINUTE, ct.ThoiGianXuatPhat, ct.ThoiGianDuKienDen) / 60.0)
                FROM PHANCONG_TOA pct
                JOIN CHUYEN_TAU ct ON pct.MaChuyenTau = ct.MaChuyenTau
                WHERE pct.MaNV = nv.MaNV
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
                  AND pct.TrangThai <> N'Nghỉ phép'
            ), 0) AS SoGioLamViec
        FROM NHAN_VIEN nv
        WHERE nv.ChucVu IN (N'LT', N'TT')
    )
    SELECT 
        CASE ChucVu
            WHEN N'LT' THEN N'Lái tàu'
            WHEN N'TT' THEN N'Toa tàu'
            ELSE N'Khác'
        END AS BoPhan,
        COUNT(DISTINCT MaNV) AS SoNhanVien,
        SUM(SoGioLamViec) AS TongSoGio,
        AVG(SoGioLamViec) AS TrungBinhGioMoiNguoi
    FROM NhanVienGioLamViec
    GROUP BY ChucVu
    ORDER BY BoPhan;
    
    RETURN 0;
END
GO
