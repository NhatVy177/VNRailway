USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_LayDanhSachNhanVienCoThePhancong
-- HOTFIX: ChucVu + JOIN NGUOI_DUNG
-- =============================================
CREATE OR ALTER PROC usp_LayDanhSachNhanVienCoThePhancong
    @MaChuyenTau NCHAR(10),
    @LoaiNhanVien NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        nv.MaNV,
        nd.HoTen,
        nv.ChucVu
    FROM NHAN_VIEN nv
    JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
    WHERE nv.ChucVu IN (N'LT', N'TT')
    ORDER BY nd.HoTen;
END
GO
