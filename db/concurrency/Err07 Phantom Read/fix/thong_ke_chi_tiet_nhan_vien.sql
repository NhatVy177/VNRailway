USE VNRAILWAY
GO

/* =============================================
   PROCEDURE: sp_ThongKeChiTietNhanVien_Fixed
   Mô tả: Sử dụng SERIALIZABLE để chặn Phantom Read.
   ============================================= */
CREATE OR ALTER PROC sp_ThongKeChiTietNhanVien_Fixed
    @Thang INT,
    @Nam INT,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- THAY ĐỔI QUAN TRỌNG: SERIALIZABLE
    -- Mức cao nhất: Khóa phạm vi (Range Lock).
    -- Bất kỳ lệnh INSERT nào vào phạm vi ngày/tháng này sẽ bị CHẶN (Block) cho đến khi Transaction này xong.
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRAN;

    DECLARE @NgayBatDau DATE = DATEFROMPARTS(@Nam, @Thang, 1);
    DECLARE @NgayKetThuc DATE = EOMONTH(@NgayBatDau);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    -- =============================================
    -- PHẦN LOGIC GỐC (GIỮ NGUYÊN)
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
    -- KIỂM CHỨNG: GIỮ KHOÁ 15s
    -- Lúc này Tab kia sẽ bị quay vòng vòng (Blocking) chứ không Insert được ngay
    -- =============================================
    PRINT N'>>> Đang giữ khoá SERIALIZABLE trong 10s... (Tab kia sẽ bị TREO)';
    WAITFOR DELAY '00:00:10';

    COMMIT TRAN;
    
    RETURN 0;
END
GO
EXEC sp_ThongKeChiTietNhanVien_Fixed 
    @Thang = 3, 
    @Nam = 2026;