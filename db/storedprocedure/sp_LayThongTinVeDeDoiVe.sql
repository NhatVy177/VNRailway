USE VNRAILWAY
GO

ALTER PROC sp_LayThongTinVeDeDoiVe
    @MaVe NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ThoiGianToiThieuDoiVe INT;
    DECLARE @TyLePhiDoiVe DECIMAL(5,4);
    
    -- Lấy tham số
    SELECT @ThoiGianToiThieuDoiVe = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS008';
    SELECT @TyLePhiDoiVe = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS007';
    
    -- Trả về thông tin vé (Thêm DISTINCT để loại bỏ dòng trùng)
    SELECT DISTINCT
        ctv.MaVe,
        ctv.MaDon,
        ddv.MaKH, -- Lấy MaKH từ DON_DAT_VE (người đặt vé)
        nd.HoTen AS TenKhachHang,
        nd.SDT,
        ctv.MaCho AS MaGhe,
        vtct.LoaiCho,
        vtct.MaChoTrong AS SoGhe,
        ctv.MaToa,
        tt.LoaiToa AS TenToa,
        ddv.MaChuyenTau,
        ddv.MaGaDi,
        ddv.MaGaDen,
        ct.ThoiGianXuatPhat,
        ct.ThoiGianDuKienDen AS ThoiGianDen,
        t.TenTuyen,
        ctv.DoiTuong,
        ctv.ThanhTien AS GiaVeCu,
        ctv.TrangThai,
        -- Tính phí đổi vé
        CAST(ctv.ThanhTien * @TyLePhiDoiVe / 100.0 AS DECIMAL(10,2)) AS PhiDoiVe,
        -- Thời gian còn lại
        DATEDIFF(MINUTE, GETDATE(), ct.ThoiGianXuatPhat) AS ThoiGianConLai,
        @ThoiGianToiThieuDoiVe AS ThoiGianToiThieuDoiVe,
        -- Kiểm tra (TEMP: Luôn cho phép đổi vé để test)
        CASE 
            WHEN ctv.TrangThai != N'Đã thanh toán' THEN 0
            -- WHEN DATEDIFF(MINUTE, GETDATE(), ct.ThoiGianXuatPhat) < @ThoiGianToiThieuDoiVe THEN 0
            -- WHEN ct.ThoiGianXuatPhat <= GETDATE() THEN 0
            ELSE 1
        END AS CoDuocDoiVe
    FROM CHI_TIET_VE ctv
    JOIN DON_DAT_VE ddv ON ctv.MaDon = ddv.MaDon
    JOIN NGUOI_DUNG nd ON ddv.MaKH = nd.MaNguoiDung -- JOIN với người đặt vé
    JOIN VI_TRI_CHO_TRONG vtct ON ctv.MaCho = vtct.MaChoTrong
    JOIN TOA_TAU tt ON ctv.MaToa = tt.MaToa
    JOIN CHUYEN_TAU ct ON ddv.MaChuyenTau = ct.MaChuyenTau
    JOIN TUYEN t ON ct.MaTuyen = t.MaTuyen
    WHERE ctv.MaVe = @MaVe;
    
    RETURN 0;
END
GO