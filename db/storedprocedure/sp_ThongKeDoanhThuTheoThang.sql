CREATE OR ALTER PROCEDURE sp_ThongKeDoanhThuTheoThang
    @ThangBatDau INT,
    @NamBatDau INT,
    @ThangKetThuc INT,
    @NamKetThuc INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NgayBatDau DATE = DATEFROMPARTS(@NamBatDau, @ThangBatDau, 1);
    DECLARE @NgayKetThuc DATE = EOMONTH(DATEFROMPARTS(@NamKetThuc, @ThangKetThuc, 1));

    SELECT 
        YEAR(ct.ThoiGianXuatPhat) AS Nam,
        MONTH(ct.ThoiGianXuatPhat) AS Thang,
        COUNT(ctv.MaVe) AS SoVe,
        ISNULL(SUM(ctv.ThanhTien), 0) AS TongDoanhThu
    FROM CHI_TIET_VE ctv
    JOIN DON_DAT_VE ddv ON ctv.MaDon = ddv.MaDon
    JOIN CHUYEN_TAU ct ON ddv.MaChuyenTau = ct.MaChuyenTau
    WHERE 
        ctv.TrangThai = N'Đã thanh toán'
        AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
        AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
    GROUP BY 
        YEAR(ct.ThoiGianXuatPhat),
        MONTH(ct.ThoiGianXuatPhat)
    ORDER BY Nam, Thang;
    
    RETURN 0;
END
GO