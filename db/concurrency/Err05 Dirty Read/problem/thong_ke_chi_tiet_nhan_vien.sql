USE VNRAILWAY
GO

CREATE OR ALTER PROC sp_ThongKeChiTietNhanVien_DirtyRead
    @Thang INT,
    @Nam INT,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    -- QUAN TRỌNG: Cho phép đọc dữ liệu chưa Commit
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @NgayBatDau DATE = DATEFROMPARTS(@Nam, @Thang, 1);
    DECLARE @NgayKetThuc DATE = EOMONTH(@NgayBatDau);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    -- (CTE logic giữ nguyên như cũ)
    WITH BangThongKe AS (
        SELECT 
            nv.MaNV, nd.HoTen, nd.SDT,
            CASE nv.ChucVu WHEN N'LT' THEN N'Lái tàu' WHEN N'TT' THEN N'Toa tàu' ELSE N'Khác' END AS BoPhan,
            ISNULL((
                SELECT SUM(DATEDIFF(MINUTE, ct.ThoiGianXuatPhat, ct.ThoiGianDuKienDen) / 60.0)
                FROM PHANCONG_LAITAU pclt JOIN CHUYEN_TAU ct ON pclt.MaChuyenTau = ct.MaChuyenTau
                WHERE pclt.MaNV = nv.MaNV AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc AND pclt.TrangThai <> N'Nghỉ phép'
            ), 0) +
            ISNULL((
                SELECT SUM(DATEDIFF(MINUTE, ct.ThoiGianXuatPhat, ct.ThoiGianDuKienDen) / 60.0)
                FROM PHANCONG_TOA pct JOIN CHUYEN_TAU ct ON pct.MaChuyenTau = ct.MaChuyenTau
                WHERE pct.MaNV = nv.MaNV AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc AND pct.TrangThai <> N'Nghỉ phép'
            ), 0) AS SoGioLamViec,
            ISNULL((
                SELECT COUNT(*) FROM PHANCONG_LAITAU pclt JOIN CHUYEN_TAU ct ON pclt.MaChuyenTau = ct.MaChuyenTau
                WHERE pclt.MaNV = nv.MaNV AND pclt.TrangThai = N'Nghỉ phép' AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
            ), 0) +
            ISNULL((
                SELECT COUNT(*) FROM PHANCONG_TOA pct JOIN CHUYEN_TAU ct ON pct.MaChuyenTau = ct.MaChuyenTau
                WHERE pct.MaNV = nv.MaNV AND pct.TrangThai = N'Nghỉ phép' AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
            ), 0) AS SoLanNghiPhep
        FROM NHAN_VIEN nv JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
        WHERE nv.ChucVu IN (N'LT', N'TT')
    )
    SELECT * FROM BangThongKe
    ORDER BY SoGioLamViec DESC, MaNV ASC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
    
    RETURN 0;
END
GO
PRINT N'Đọc báo cáo thống kê (Dirty Read)...';

-- Xem kết quả thống kê của tháng/năm chứa chuyến tàu trên
EXEC sp_ThongKeChiTietNhanVien_DirtyRead 
    @Thang = 3, 
    @Nam = 2026;