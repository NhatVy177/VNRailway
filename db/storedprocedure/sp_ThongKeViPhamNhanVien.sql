USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_ThongKeViPhamNhanVien
-- Danh sách nhân viên vi phạm (nghỉ phép nhiều)
-- =============================================
CREATE OR ALTER PROC sp_ThongKeViPhamNhanVien
    @Thang INT,
    @Nam INT,
    @NguongViPham INT = 3  -- Ngưỡng số lần nghỉ phép tối đa
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NgayBatDau DATE = DATEFROMPARTS(@Nam, @Thang, 1);
    DECLARE @NgayKetThuc DATE = EOMONTH(@NgayBatDau);

    SELECT 
        nv.MaNV,
        nd.HoTen,
        nd.SDT,
        CASE nv.ChucVu
            WHEN N'LT' THEN N'Lái tàu'
            WHEN N'TT' THEN N'Toa tàu'
            ELSE N'Khác'
        END AS BoPhan,
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
        ), 0) AS SoLanNghiPhep,
        -- Số giờ làm việc
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
        ), 0) AS SoGioLamViec
    FROM NHAN_VIEN nv
    JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
    WHERE nv.ChucVu IN (N'LT', N'TT')
      -- Chỉ lấy những nhân viên có số lần nghỉ phép >= ngưỡng
      AND (
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
          ), 0)
      ) >= @NguongViPham
    ORDER BY SoLanNghiPhep DESC;
    
    RETURN 0;
END
GO
