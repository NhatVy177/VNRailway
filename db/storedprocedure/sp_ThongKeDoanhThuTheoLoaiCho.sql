CREATE OR ALTER PROCEDURE sp_ThongKeDoanhThuTheoLoaiCho
    @NgayBatDau DATE,
    @NgayKetThuc DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        tt.LoaiToa,
        CASE 
            WHEN tt.LoaiToa LIKE N'GH%' THEN N'Ghế ngồi'
            WHEN tt.LoaiToa LIKE N'GI%' THEN N'Giường nằm'
            ELSE tt.LoaiToa
        END AS TenLoaiCho,
        COUNT(DISTINCT ctv.MaVe) AS SoVe,
        SUM(ISNULL(ctv.ThanhTien, 0)) AS TongDoanhThu,
        AVG(ISNULL(ctv.ThanhTien, 0)) AS DoanhThuTrungBinh
    FROM CHI_TIET_VE ctv
    JOIN DON_DAT_VE ddv ON ctv.MaDon = ddv.MaDon
    JOIN CHUYEN_TAU ct ON ddv.MaChuyenTau = ct.MaChuyenTau
    JOIN TOA_TAU tt ON ctv.MaToa = tt.MaToa
    WHERE 
        CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
        AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
        AND ctv.TrangThai = N'Đã thanh toán'
    GROUP BY tt.LoaiToa
    ORDER BY TongDoanhThu DESC;
    
    RETURN 0;
END
GO