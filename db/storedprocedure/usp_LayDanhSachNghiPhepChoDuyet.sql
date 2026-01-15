USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_LayDanhSachNghiPhepChoDuyet
-- Mô tả: Lấy danh sách đơn nghỉ phép chờ duyệt
-- =============================================
CREATE OR ALTER PROC usp_LayDanhSachNghiPhepChoDuyet
    @MaNVQL NCHAR(10) = NULL,
    @MaChuyenTau NCHAR(10) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    WITH DonNghiPhep AS (
        -- LÁI TÀU
        SELECT
            pl.MaChuyenTau,
            ct.ThoiGianXuatPhat,
            ct.ThoiGianDuKienDen,
            ct.MaTuyen,
            ct.MaDoanTau,
            pl.MaNV,
            nd.HoTen AS TenNhanVien,
            pl.VaiTro,
            N'LT' AS ChucVu,
            pl.MaNVQL,
            ndql.HoTen AS TenNVQL
        FROM PHANCONG_LAITAU pl
        JOIN CHUYEN_TAU ct ON pl.MaChuyenTau = ct.MaChuyenTau
        JOIN NHAN_VIEN nv ON pl.MaNV = nv.MaNV
        JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
        JOIN NHAN_VIEN nvql ON pl.MaNVQL = nvql.MaNV
        JOIN NGUOI_DUNG ndql ON nvql.MaNV = ndql.MaNguoiDung
        WHERE pl.TrangThai = N'Nghỉ phép'
          AND (@MaNVQL IS NULL OR pl.MaNVQL = @MaNVQL)
          AND (@MaChuyenTau IS NULL OR pl.MaChuyenTau = @MaChuyenTau)

        UNION ALL

        -- TOA TÀU
        SELECT
            pt.MaChuyenTau,
            ct.ThoiGianXuatPhat,
            ct.ThoiGianDuKienDen,
            ct.MaTuyen,
            ct.MaDoanTau,
            pt.MaNV,
            nd.HoTen,
            pt.VaiTro,
            N'TT',
            pt.MaNVQL,
            ndql.HoTen
        FROM PHANCONG_TOA pt
        JOIN CHUYEN_TAU ct ON pt.MaChuyenTau = ct.MaChuyenTau
        JOIN NHAN_VIEN nv ON pt.MaNV = nv.MaNV
        JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
        JOIN NHAN_VIEN nvql ON pt.MaNVQL = nvql.MaNV
        JOIN NGUOI_DUNG ndql ON nvql.MaNV = ndql.MaNguoiDung
        WHERE pt.TrangThai = N'Nghỉ phép'
          AND (@MaNVQL IS NULL OR pt.MaNVQL = @MaNVQL)
          AND (@MaChuyenTau IS NULL OR pt.MaChuyenTau = @MaChuyenTau)
    )
    SELECT *,
           COUNT(*) OVER() AS TotalRecords
    FROM DonNghiPhep
    ORDER BY ThoiGianXuatPhat
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    RETURN 0;
END
GO
