USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_LayDanhSachNhanVienVoiGioLamViec
-- Lấy danh sách nhân viên CÓ THỂ phân công với số giờ làm việc trong tuần
-- + Hỗ trợ tìm kiếm theo mã hoặc tên
-- =============================================
CREATE OR ALTER PROC usp_LayDanhSachNhanVienVoiGioLamViec
    @MaChuyenTau NCHAR(10),
    @LoaiNhanVien NCHAR(2), -- 'LT' = Lái tàu, 'TT' = Toa tàu
    @SearchKeyword NVARCHAR(100) = NULL, -- Từ khóa tìm kiếm (mã hoặc tên)
    @ThongBao NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra chuyến tàu có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
    BEGIN
        SET @ThongBao = N'Chuyến tàu không tồn tại.';
        RETURN -1009;
    END

    -- Lấy thời gian xuất phát của chuyến
    DECLARE @ThoiGianXuatPhat DATETIME;
    SELECT @ThoiGianXuatPhat = ThoiGianXuatPhat
    FROM CHUYEN_TAU
    WHERE MaChuyenTau = @MaChuyenTau;

    -- Lấy tuần của chuyến tàu (đầu tuần và cuối tuần)
    DECLARE @DauTuan DATETIME, @CuoiTuan DATETIME;
    SELECT @DauTuan = DauTuan, @CuoiTuan = CuoiTuan
    FROM fn_LayTuan(@ThoiGianXuatPhat);

    -- Lấy danh sách nhân viên với số giờ làm việc trong tuần
    SELECT 
        nv.MaNV,
        nd.HoTen,
        nd.SDT,
        nv.ChucVu,
        
        -- Tính tổng số giờ làm việc trong tuần
        ISNULL((
            SELECT SUM(
                -- Tính từ thời gian chạy chuyến (không có cột ThoiGianLamViec)
                DATEDIFF(MINUTE, ct.ThoiGianXuatPhat, ct.ThoiGianDuKienDen) / 60.0
            )
            FROM PHANCONG_LAITAU pclt
            JOIN CHUYEN_TAU ct ON pclt.MaChuyenTau = ct.MaChuyenTau
            WHERE pclt.MaNV = nv.MaNV
              AND ct.ThoiGianXuatPhat >= @DauTuan
              AND ct.ThoiGianXuatPhat < @CuoiTuan
              AND pclt.TrangThai <> N'Nghỉ phép'
        ), 0) + 
        ISNULL((
            SELECT SUM(
                DATEDIFF(MINUTE, ct.ThoiGianXuatPhat, ct.ThoiGianDuKienDen) / 60.0
            )
            FROM PHANCONG_TOA pct
            JOIN CHUYEN_TAU ct ON pct.MaChuyenTau = ct.MaChuyenTau
            WHERE pct.MaNV = nv.MaNV
              AND ct.ThoiGianXuatPhat >= @DauTuan
              AND ct.ThoiGianXuatPhat < @CuoiTuan
              AND pct.TrangThai <> N'Nghỉ phép'
        ), 0) AS SoGioLamViecTrongTuan

    FROM NHAN_VIEN nv
    JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
    
    WHERE 
        -- Lọc theo loại nhân viên
        nv.ChucVu = @LoaiNhanVien
        
        -- Chỉ lấy nhân viên CHƯA được phân công cho chuyến này
        AND nv.MaNV NOT IN (
            SELECT MaNV FROM PHANCONG_LAITAU WHERE MaChuyenTau = @MaChuyenTau
            UNION
            SELECT MaNV FROM PHANCONG_TOA WHERE MaChuyenTau = @MaChuyenTau
        )
        
        -- Tìm kiếm theo mã hoặc tên
        AND (
            @SearchKeyword IS NULL 
            OR @SearchKeyword = ''
            OR nv.MaNV LIKE '%' + @SearchKeyword + '%'
            OR nd.HoTen LIKE '%' + @SearchKeyword + '%'
        )
        
    -- Sắp xếp theo số giờ làm việc tăng dần (ưu tiên người làm ít giờ)
    ORDER BY SoGioLamViecTrongTuan ASC, nd.HoTen ASC;

    SET @ThongBao = N'Lấy danh sách nhân viên thành công.';
    RETURN 0;
END
GO