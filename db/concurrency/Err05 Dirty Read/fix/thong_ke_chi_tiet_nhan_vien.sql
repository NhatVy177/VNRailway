USE VNRAILWAY
GO

/* =============================================
   Procedure: sp_ThongKeChiTietNhanVien
   Mô tả: Phiên bản CHUẨN (Fix lỗi Dirty Read)
   - Isolation: READ COMMITTED (Mặc định) -> Sẽ chờ (Block) nếu gặp dữ liệu chưa commit
   - Bao gồm logic sắp xếp theo giờ làm việc giảm dần
   ============================================= */
CREATE OR ALTER PROC sp_ThongKeChiTietNhanVien
    @Thang INT,
    @Nam INT,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    --  FIX: Đảm bảo không đọc dữ liệu bẩn
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    DECLARE @NgayBatDau DATE = DATEFROMPARTS(@Nam, @Thang, 1);
    DECLARE @NgayKetThuc DATE = EOMONTH(@NgayBatDau);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    -- CTE tính toán (Logic nghiệp vụ giữ nguyên)
    WITH BangThongKe AS (
        SELECT 
            nv.MaNV,
            nd.HoTen,
            nd.SDT,
            CASE nv.ChucVu
                WHEN N'LT' THEN N'Lái tàu'
                WHEN N'TT' THEN N'Toa tàu'
                ELSE N'Khác'
            END AS BoPhan,
            -- Tính số giờ làm việc
            ISNULL((
                SELECT SUM(DATEDIFF(MINUTE, ct.ThoiGianXuatPhat, ct.ThoiGianDuKienDen) / 60.0)
                FROM PHANCONG_LAITAU pclt
                JOIN CHUYEN_TAU ct ON pclt.MaChuyenTau = ct.MaChuyenTau
                WHERE pclt.MaNV = nv.MaNV
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
                  AND pclt.TrangThai <> N'Nghỉ phép'
            ), 0) +
            ISNULL((
                SELECT SUM(DATEDIFF(MINUTE, ct.ThoiGianXuatPhat, ct.ThoiGianDuKienDen) / 60.0)
                FROM PHANCONG_TOA pct
                JOIN CHUYEN_TAU ct ON pct.MaChuyenTau = ct.MaChuyenTau
                WHERE pct.MaNV = nv.MaNV
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
                  AND pct.TrangThai <> N'Nghỉ phép'
            ), 0) AS SoGioLamViec,
            -- Số lần nghỉ phép
            ISNULL((
                SELECT COUNT(*)
                FROM PHANCONG_LAITAU pclt
                JOIN CHUYEN_TAU ct ON pclt.MaChuyenTau = ct.MaChuyenTau
                WHERE pclt.MaNV = nv.MaNV
                  AND pclt.TrangThai = N'Nghỉ phép'
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
            ), 0) +
            ISNULL((
                SELECT COUNT(*)
                FROM PHANCONG_TOA pct
                JOIN CHUYEN_TAU ct ON pct.MaChuyenTau = ct.MaChuyenTau
                WHERE pct.MaNV = nv.MaNV
                  AND pct.TrangThai = N'Nghỉ phép'
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
                  AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
            ), 0) AS SoLanNghiPhep
        FROM NHAN_VIEN nv
        JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
        WHERE nv.ChucVu IN (N'LT', N'TT')
    )
    -- Trả kết quả đã sắp xếp
    SELECT * FROM BangThongKe
    ORDER BY SoGioLamViec DESC, MaNV ASC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
    
    -- Tổng số bản ghi
    SELECT COUNT(*) AS TotalRecords
    FROM NHAN_VIEN
    WHERE ChucVu IN (N'LT', N'TT');
    
    RETURN 0;
END
GO
EXEC sp_ThongKeChiTietNhanVien
    @Thang = 3, 
    @Nam = 2026;