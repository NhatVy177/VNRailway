CREATE PROCEDURE sp_ThongKeDoanhThuTheoTuyen
    @NgayBatDau DATE,
    @NgayKetThuc DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TongDoanhThuToanBo DECIMAL(12, 2);
    
    SELECT @TongDoanhThuToanBo = SUM(ISNULL(ctv.ThanhTien, 0))
    FROM CHUYEN_TAU ct
    JOIN DON_DAT_VE ddv ON ct.MaChuyenTau = ddv.MaChuyenTau
    JOIN CHI_TIET_VE ctv ON ddv.MaDon = ctv.MaDon
    WHERE 
        CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
        AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
        AND ctv.TrangThai = N'Đã thanh toán';
    
    SET @TongDoanhThuToanBo = ISNULL(@TongDoanhThuToanBo, 0);

    SELECT 
        t.MaTuyen,
        t.TenTuyen,
        COUNT(ctv.MaVe) AS SoVe,
        ISNULL(SUM(ctv.ThanhTien), 0) AS TongDoanhThu,
        CASE 
            WHEN @TongDoanhThuToanBo > 0 
            THEN (ISNULL(SUM(ctv.ThanhTien), 0) * 100.0 / @TongDoanhThuToanBo)
            ELSE 0
        END AS TyLePhanTram
    FROM TUYEN t
    JOIN CHUYEN_TAU ct ON t.MaTuyen = ct.MaTuyen
    JOIN DON_DAT_VE ddv ON ct.MaChuyenTau = ddv.MaChuyenTau
    JOIN CHI_TIET_VE ctv ON ddv.MaDon = ctv.MaDon
    WHERE 
        ctv.TrangThai = N'Đã thanh toán'
        AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
        AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
    GROUP BY t.MaTuyen, t.TenTuyen
    ORDER BY TongDoanhThu DESC;
    
    RETURN 0;
END
GO