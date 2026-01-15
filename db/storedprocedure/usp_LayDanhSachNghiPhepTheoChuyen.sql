USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_LayDanhSachNghiPhepTheoChuyen
-- Mô tả: Lấy danh sách nghỉ phép của 1 chuyến tàu
-- =============================================
CREATE OR ALTER PROC usp_LayDanhSachNghiPhepTheoChuyen
    @MaChuyenTau NCHAR(10),
    @ThongBao NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
    BEGIN
        SET @ThongBao = N'Chuyến tàu không tồn tại.';
        RETURN -1009;
    END

    -- ===== LÁI TÀU =====
    SELECT
        ROW_NUMBER() OVER (ORDER BY nd.HoTen) AS STT,
        pl.VaiTro,
        pl.MaNV,
        nd.HoTen AS TenNhanVien,
        pl.TrangThai,
        pl_thay.MaNV AS MaNVThayThe,
        nd_thay.HoTen AS TenNVThayThe,
        N'LT' AS ChucVu
    FROM PHANCONG_LAITAU pl
    JOIN NHAN_VIEN nv ON pl.MaNV = nv.MaNV
    JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
    LEFT JOIN PHANCONG_LAITAU pl_thay
        ON pl_thay.MaChuyenTau = pl.MaChuyenTau
       AND pl_thay.VaiTro = pl.VaiTro
       AND pl_thay.TrangThai = N'Thay thế'
    LEFT JOIN NHAN_VIEN nv_thay ON pl_thay.MaNV = nv_thay.MaNV
    LEFT JOIN NGUOI_DUNG nd_thay ON nv_thay.MaNV = nd_thay.MaNguoiDung
    WHERE pl.MaChuyenTau = @MaChuyenTau
      AND pl.TrangThai = N'Nghỉ phép'

    UNION ALL

    -- ===== TOA TÀU =====
    SELECT
        ROW_NUMBER() OVER (ORDER BY nd.HoTen),
        pt.VaiTro,
        pt.MaNV,
        nd.HoTen,
        pt.TrangThai,
        pt_thay.MaNV,
        nd_thay.HoTen,
        N'TT'
    FROM PHANCONG_TOA pt
    JOIN NHAN_VIEN nv ON pt.MaNV = nv.MaNV
    JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
    LEFT JOIN PHANCONG_TOA pt_thay
        ON pt_thay.MaChuyenTau = pt.MaChuyenTau
       AND pt_thay.MaToa = pt.MaToa
       AND pt_thay.VaiTro = pt.VaiTro
       AND pt_thay.TrangThai = N'Thay thế'
    LEFT JOIN NHAN_VIEN nv_thay ON pt_thay.MaNV = nv_thay.MaNV
    LEFT JOIN NGUOI_DUNG nd_thay ON nv_thay.MaNV = nd_thay.MaNguoiDung
    WHERE pt.MaChuyenTau = @MaChuyenTau
      AND pt.TrangThai = N'Nghỉ phép'
    ORDER BY STT;

    SET @ThongBao = N'Lấy danh sách nghỉ phép thành công.';
    RETURN 0;
END
GO
