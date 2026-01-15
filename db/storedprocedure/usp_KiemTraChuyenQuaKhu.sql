USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_KiemTraChuyenQuaKhu
-- Mô tả: Kiểm tra chuyến tàu đã chạy hay chưa
-- =============================================
CREATE OR ALTER PROC usp_KiemTraChuyenQuaKhu
    @MaChuyenTau NCHAR(10),
    @LaChuyenQuaKhu BIT OUT,
    @ThongBao NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ThoiGianDuKienDen DATETIME;

    SELECT @ThoiGianDuKienDen = ThoiGianDuKienDen
    FROM CHUYEN_TAU
    WHERE MaChuyenTau = @MaChuyenTau;

    IF @ThoiGianDuKienDen IS NULL
    BEGIN
        SET @LaChuyenQuaKhu = 0;
        SET @ThongBao = N'Chuyến tàu không tồn tại.';
        RETURN -1009;
    END

    IF @ThoiGianDuKienDen < GETDATE()
    BEGIN
        SET @LaChuyenQuaKhu = 1;
        SET @ThongBao = N'Chuyến tàu đã hoàn thành.';
    END
    ELSE
    BEGIN
        SET @LaChuyenQuaKhu = 0;
        SET @ThongBao = N'Chuyến tàu chưa chạy.';
    END

    RETURN 0;
END
GO
