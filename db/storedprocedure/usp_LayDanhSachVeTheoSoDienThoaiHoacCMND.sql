USE VNRAILWAY
GO

-- ===========================================================================
-- Stored Procedure: usp_LayDanhSachVeTheoSoDienThoaiHoacCMND
-- Mô tả: Lấy danh sách vé đã đặt theo số điện thoại hoặc CMND của người đặt
-- Dành cho nhân viên bán vé tra cứu vé của khách hàng
-- FIX: JOIN với NGUOI_DUNG để lấy CMND, SDT, HoTen
-- ===========================================================================
CREATE OR ALTER PROCEDURE usp_LayDanhSachVeTheoSoDienThoaiHoacCMND
    @SoDienThoai NVARCHAR(20) = NULL,
    @CMND NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra phải có ít nhất 1 tham số
    IF @SoDienThoai IS NULL AND @CMND IS NULL
    BEGIN
        RAISERROR(N'Vui lòng nhập số điện thoại hoặc CMND để tìm kiếm', 16, 1);
        RETURN;
    END
    
    -- Lấy danh sách vé dựa trên thông tin người đặt
    SELECT 
        ddv.MaDon,
        ddv.ThoiGianDatve,
        ddv.TongTien,
        CASE 
            WHEN v.TrangThai = N'Chưa thanh toán' THEN N'Chưa thanh toán'
            WHEN v.TrangThai = N'Đã thanh toán' THEN N'Đã thanh toán'
            WHEN v.TrangThai = N'Đã hủy' THEN N'Đã hủy'
            ELSE N'Chưa thanh toán'
        END as TrangThaiThanhToan,
        
        -- Thông tin chuyến tàu
        ct.MaChuyenTau,
        dt.TenTau,
        ct.ThoiGianXuatPhat as ThoiGianKhoiHanh,
        
        -- Thông tin ga
        ddv.MaGaDi,
        gaDi.TenGa as TenGaDi,
        ddv.MaGaDen,
        gaDen.TenGa as TenGaDen,
        
        -- Thông tin vé (hành khách)
        v.MaVe,
        v.MaToa,
        v.MaCho,
        CASE 
            WHEN tt.LoaiToa = 'GH' THEN N'Ghế ngồi'
            WHEN tt.LoaiToa = 'GI4' THEN N'Giường nằm 4'
            WHEN tt.LoaiToa = 'GI6' THEN N'Giường nằm 6'
            ELSE N'Không xác định'
        END as LoaiCho,
        
        -- Thông tin hành khách (từ NGUOI_DUNG)
        ndHK.HoTen as TenHanhKhach,
        ndHK.CMND as CMNDHanhKhach,
        v.ThanhTien as GiaVe,
        v.TrangThai as TrangThaiVe,
        
        -- Thông tin người đặt (từ NGUOI_DUNG)
        ndNguoiDat.HoTen as NguoiDatHoTen,
        ndNguoiDat.SDT as NguoiDatSDT,
        ndNguoiDat.CMND as NguoiDatCMND
        
    FROM DON_DAT_VE ddv
    INNER JOIN CHI_TIET_VE v ON ddv.MaDon = v.MaDon
    INNER JOIN CHUYEN_TAU ct ON ddv.MaChuyenTau = ct.MaChuyenTau
    INNER JOIN DOAN_TAU dt ON ct.MaDoanTau = dt.MaDoanTau
    INNER JOIN GA gaDi ON ddv.MaGaDi = gaDi.MaGa
    INNER JOIN GA gaDen ON ddv.MaGaDen = gaDen.MaGa
    INNER JOIN TOA_TAU tt ON v.MaToa = tt.MaToa
    
    -- JOIN để lấy thông tin NGƯỜI ĐẶT từ NGUOI_DUNG
    INNER JOIN KHACH_HANG kh ON ddv.MaKH = kh.MaKH
    INNER JOIN NGUOI_DUNG ndNguoiDat ON kh.MaKH = ndNguoiDat.MaNguoiDung
    
    -- JOIN để lấy thông tin HÀNH KHÁCH từ NGUOI_DUNG
    INNER JOIN KHACH_HANG khHK ON v.MaKH = khHK.MaKH
    INNER JOIN NGUOI_DUNG ndHK ON khHK.MaKH = ndHK.MaNguoiDung
    
    WHERE 
        (@SoDienThoai IS NOT NULL AND ndNguoiDat.SDT = @SoDienThoai)
        OR 
        (@CMND IS NOT NULL AND ndNguoiDat.CMND = @CMND)
    
    ORDER BY ddv.ThoiGianDatve DESC, v.MaVe;
END;
GO