CREATE OR ALTER PROCEDURE sp_ThongKeDoanhThu
    @NgayBatDau DATE,
    @NgayKetThuc DATE,
    @TieuChi NVARCHAR(20) = N'Tổng thể'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        COUNT(ctv.MaVe) AS TongSoVe,
        ISNULL(SUM(ctv.ThanhTien), 0) AS TongDoanhThu,
        CASE WHEN COUNT(ctv.MaVe) > 0 
             THEN ISNULL(SUM(ctv.ThanhTien), 0) / COUNT(ctv.MaVe)
             ELSE 0 
        END AS DoanhThuTrungBinhMoiVe,
        (SELECT COUNT(DISTINCT ct2.MaChuyenTau) 
         FROM CHUYEN_TAU ct2 
         WHERE CAST(ct2.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
           AND CAST(ct2.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc) AS SoChuyenTau,
        COUNT(DISTINCT ctv.MaKH) AS SoKhachHang
    FROM CHI_TIET_VE ctv
    JOIN DON_DAT_VE ddv ON ctv.MaDon = ddv.MaDon
    JOIN CHUYEN_TAU ct ON ddv.MaChuyenTau = ct.MaChuyenTau
    WHERE 
        ctv.TrangThai = N'Đã thanh toán'
        AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
        AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc;
    
    RETURN 0;
END
GO