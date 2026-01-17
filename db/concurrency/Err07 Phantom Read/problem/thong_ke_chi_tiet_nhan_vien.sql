USE VNRAILWAY
GO

/* =============================================
   PROCEDURE: sp_ThongKeChiTietNhanVien_Phantom
   Mô tả: Giữ nguyên logic gốc. Thêm Waitfor Delay cuối transaction 
          để kiểm chứng việc có bị chặn Insert hay không.
   ============================================= */
CREATE OR ALTER PROC sp_ThongKeChiTietNhanVien_Phantom
    @Thang INT,
    @Nam INT,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    --  THIẾT LẬP: REPEATABLE READ
    -- Mức này giữ khóa các dòng đã đọc nhưng KHÔNG khóa việc chèn mới (Phantom).
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    BEGIN TRAN;

    DECLARE @NgayBatDau DATE = DATEFROMPARTS(@Nam, @Thang, 1);
    DECLARE @NgayKetThuc DATE = EOMONTH(@NgayBatDau);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    -- =============================================
    -- PHẦN LOGIC GỐC (KHÔNG SỬA ĐỔI)
    -- =============================================
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
    SELECT * FROM BangThongKe
    ORDER BY SoGioLamViec DESC, MaNV ASC 
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
    
    -- =============================================
    -- BẪY PHANTOM: GIỮ TRANSACTION 15s SAU KHI ĐỌC
    -- =============================================
    PRINT N'>>> Đã đọc xong dữ liệu. Đang giữ Transaction 15s... (Hãy Insert ở Tab kia ngay)';
    WAITFOR DELAY '00:00:15';

    COMMIT TRAN;
    
    RETURN 0;
END
GO
EXEC sp_ThongKeChiTietNhanVien_Phantom 
    @Thang = 3, 
    @Nam = 2026;