CREATE OR ALTER PROC usp_LayChiTietChuyenTauPhanCong
    @MaChuyenTau NCHAR(10),
    @ThongBao NVARCHAR(255) OUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra chuyến tàu tồn tại
    IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
    BEGIN
        SET @ThongBao = N'Chuyến tàu không tồn tại.';
        RETURN -1009;
    END

    -- Lấy thời gian mở/đóng bán vé từ tham số
    DECLARE @NgayMoBanVeTruocXuatPhat INT;
    DECLARE @NgayDongBanVeTruocXuatPhat INT;

    SELECT @NgayMoBanVeTruocXuatPhat = CAST(GiaTriThamSo AS INT)
    FROM THAM_SO
    WHERE MaThamSo = 'TS002';  -- Thời điểm mở bán vé trước thời điểm tàu xuất phát (ngày)

    SELECT @NgayDongBanVeTruocXuatPhat = CAST(GiaTriThamSo AS INT)
    FROM THAM_SO
    WHERE MaThamSo = 'TS003';  -- Thời điểm đóng bán vé trước thời điểm tàu xuất phát (ngày)

    -- Lấy chi tiết chuyến tàu
    SELECT 
        ct.MaChuyenTau,
        ct.MaTuyen,
        t.TenTuyen,
        ct.MaDoanTau,
        dt.TenTau,
        dt.LoaiTau,
        ct.ThoiGianXuatPhat,
        ct.ThoiGianDuKienDen,
        
        -- Tính toán thời gian mở/đóng bán vé
        DATEADD(DAY, -ISNULL(@NgayMoBanVeTruocXuatPhat, 30), ct.ThoiGianXuatPhat) AS ThoiGianMoBanVe,
        DATEADD(DAY, -ISNULL(@NgayDongBanVeTruocXuatPhat, 1), ct.ThoiGianXuatPhat) AS ThoiGianDongBanVe,
        
        -- Số vé đã bán (COUNT CHI_TIET_VE qua DON_DAT_VE)
        ISNULL((
            SELECT COUNT(*)
            FROM CHI_TIET_VE ctv
            JOIN DON_DAT_VE ddv ON ctv.MaDon = ddv.MaDon
            WHERE ddv.MaChuyenTau = ct.MaChuyenTau
              AND ctv.TrangThai = N'Đã thanh toán'
        ), 0) AS SoVeDaBan,
        
        -- Doanh thu (SUM TongTien từ DON_DAT_VE)
        ISNULL((
            SELECT SUM(ddv.TongTien)
            FROM DON_DAT_VE ddv
            WHERE ddv.MaChuyenTau = ct.MaChuyenTau
              AND EXISTS (
                  SELECT 1 
                  FROM CHI_TIET_VE ctv 
                  WHERE ctv.MaDon = ddv.MaDon 
                    AND ctv.TrangThai = N'Đã thanh toán'
              )
        ), 0) AS DoanhThu

    FROM CHUYEN_TAU ct
    JOIN TUYEN t ON ct.MaTuyen = t.MaTuyen
    JOIN DOAN_TAU dt ON ct.MaDoanTau = dt.MaDoanTau
    WHERE ct.MaChuyenTau = @MaChuyenTau;

    SET @ThongBao = N'Lấy chi tiết chuyến tàu thành công.';
    RETURN 0;
END
GO