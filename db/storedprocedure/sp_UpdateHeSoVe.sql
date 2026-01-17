USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_UpdateHeSoVe
-- Cập nhật hệ số vé
-- =============================================
CREATE OR ALTER PROC sp_UpdateHeSoVe
    @MaHeSo NCHAR(5),
    @NgayBD DATETIME,
    @NgayKT DATETIME,
    @HeSo DECIMAL(2, 1),
    @GhiChu NVARCHAR(255),
    @ThongBao NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate: Kiểm tra mã hệ số có tồn tại
        IF NOT EXISTS (SELECT 1 FROM HE_SO_VE WHERE MaHeSo = @MaHeSo)
        BEGIN
            SET @ThongBao = N'Mã hệ số không tồn tại.';
            RETURN -1;
        END
        
        -- Validate: Ngày bắt đầu < Ngày kết thúc
        IF @NgayBD >= @NgayKT
        BEGIN
            SET @ThongBao = N'Ngày bắt đầu phải nhỏ hơn ngày kết thúc.';
            RETURN -2;
        END
        
        -- Validate: Hệ số phải > 0
        IF @HeSo <= 0
        BEGIN
            SET @ThongBao = N'Hệ số phải lớn hơn 0.';
            RETURN -3;
        END
        
        -- Validate: Kiểm tra trùng lặp thời gian với các hệ số khác
        IF EXISTS (
            SELECT 1 
            FROM HE_SO_VE 
            WHERE MaHeSo <> @MaHeSo
              AND (
                  (@NgayBD >= NgayBD AND @NgayBD < NgayKT) OR
                  (@NgayKT > NgayBD AND @NgayKT <= NgayKT) OR
                  (@NgayBD <= NgayBD AND @NgayKT >= NgayKT)
              )
        )
        BEGIN
            SET @ThongBao = N'Khoảng thời gian bị trùng với hệ số khác.';
            RETURN -4;
        END
        
        -- Cập nhật
        UPDATE HE_SO_VE
        SET NgayBD = @NgayBD,
            NgayKT = @NgayKT,
            HeSo = @HeSo,
            GhiChu = @GhiChu
        WHERE MaHeSo = @MaHeSo;
        
        SET @ThongBao = N'Cập nhật hệ số vé thành công.';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        SET @ThongBao = N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -999;
    END CATCH
END
GO
