USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_ThongKeChuyenTauTheoThang
-- Thống kê số chuyến tàu theo tháng (cho biểu đồ)
-- =============================================
CREATE OR ALTER PROC sp_ThongKeChuyenTauTheoThang
    @ThangBatDau INT,
    @NamBatDau INT,
    @ThangKetThuc INT,
    @NamKetThuc INT,
    @MaTuyen NCHAR(5) = NULL  -- Optional: lọc theo tuyến
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NgayBatDau DATE = DATEFROMPARTS(@NamBatDau, @ThangBatDau, 1);
    DECLARE @NgayKetThuc DATE = EOMONTH(DATEFROMPARTS(@NamKetThuc, @ThangKetThuc, 1));

    SELECT 
        YEAR(ct.ThoiGianXuatPhat) AS Nam,
        MONTH(ct.ThoiGianXuatPhat) AS Thang,
        COUNT(ct.MaChuyenTau) AS SoChuyen
    FROM CHUYEN_TAU ct
    WHERE 
        CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
        AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
        AND (@MaTuyen IS NULL OR ct.MaTuyen = @MaTuyen)
    GROUP BY 
        YEAR(ct.ThoiGianXuatPhat),
        MONTH(ct.ThoiGianXuatPhat)
    ORDER BY Nam, Thang;
    
    RETURN 0;
END
GO
