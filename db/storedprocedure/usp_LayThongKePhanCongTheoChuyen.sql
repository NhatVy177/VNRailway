USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_LayThongKePhanCongTheoChuyen
-- =============================================
CREATE OR ALTER PROC usp_LayThongKePhanCongTheoChuyen
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

    DECLARE @TongViTri INT, @DaPhanCong INT, @SoNghiPhep INT;

    -- Tổng vị trí = 2 lái tàu + 1 Trưởng toa + số toa (mỗi toa 1 nhân viên)
    SELECT @TongViTri = 3 + COUNT(*)
    FROM TOA_TAU tt
    JOIN CHUYEN_TAU ct ON tt.MaDoanTau = ct.MaDoanTau
    WHERE ct.MaChuyenTau = @MaChuyenTau;

    SELECT @DaPhanCong = COUNT(DISTINCT MaNV)
    FROM (
        SELECT MaNV FROM PHANCONG_LAITAU WHERE MaChuyenTau = @MaChuyenTau AND TrangThai <> N'Nghỉ phép'
        UNION ALL
        SELECT MaNV FROM PHANCONG_TOA WHERE MaChuyenTau = @MaChuyenTau AND TrangThai <> N'Nghỉ phép'
    ) x;

    SELECT @SoNghiPhep = COUNT(*)
    FROM (
        SELECT MaNV FROM PHANCONG_LAITAU WHERE MaChuyenTau = @MaChuyenTau AND TrangThai = N'Nghỉ phép'
        UNION ALL
        SELECT MaNV FROM PHANCONG_TOA WHERE MaChuyenTau = @MaChuyenTau AND TrangThai = N'Nghỉ phép'
    ) y;

    SELECT
        @TongViTri AS TongSoViTri,
        @DaPhanCong AS SoPhanCongDaCo,
        @SoNghiPhep AS SoNghiPhep,
        (@TongViTri - @DaPhanCong) AS SoConThieu;

    SET @ThongBao = N'Lấy thống kê thành công.';
    RETURN 0;
END
GO
