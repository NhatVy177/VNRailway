USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_LayDanhSachNhanVienCoThePhancong
-- HOTFIX: ChucVu + JOIN NGUOI_DUNG + Search by MaNV/HoTen
-- =============================================
CREATE OR ALTER PROC usp_LayDanhSachNhanVienCoThePhancong
    @MaChuyenTau NCHAR(10),
    @LoaiNhanVien NVARCHAR(20),
    @SearchKeyword NVARCHAR(100) = NULL  -- Từ khóa tìm kiếm (mã hoặc tên)
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
        AND (
            @SearchKeyword IS NULL 
            OR @SearchKeyword = ''
            OR nv.MaNV LIKE '%' + @SearchKeyword + '%'
            OR nd.HoTen LIKE '%' + @SearchKeyword + '%'
        )
    ORDER BY nd.HoTen;
END
GO
