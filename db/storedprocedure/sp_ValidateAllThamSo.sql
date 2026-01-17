USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_ValidateAllThamSo (NEW)
-- Kiểm tra cross-validation giữa các tham số
-- =============================================
CREATE OR ALTER PROC sp_ValidateAllThamSo
    @IsValid BIT OUT,
    @ThongBao NVARCHAR(500) OUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @IsValid = 1;
    SET @ThongBao = N'';
    
    BEGIN TRY
        DECLARE @ThoiGianMoBan DECIMAL(12, 2);
        DECLARE @ThoiGianDongBan DECIMAL(12, 2);
        DECLARE @KmMin DECIMAL(12, 2);
        DECLARE @KmMax DECIMAL(12, 2);
        DECLARE @GioMin DECIMAL(12, 2);
        DECLARE @GioMax DECIMAL(12, 2);
        
        -- Lấy giá trị hiện tại
        SELECT @ThoiGianMoBan = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS002';
        SELECT @ThoiGianDongBan = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS003';
        SELECT @KmMin = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS014';
        SELECT @KmMax = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS015';
        SELECT @GioMin = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS016';
        SELECT @GioMax = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS017';
        
        -- Validate cross-constraints
        IF (@ThoiGianMoBan * 24 * 60) <= @ThoiGianDongBan
        BEGIN
            SET @IsValid = 0;
            SET @ThongBao = @ThongBao + N'Thời gian mở bán phải lớn hơn thời gian đóng bán. ';
        END
        
        IF @KmMin >= @KmMax
        BEGIN
            SET @IsValid = 0;
            SET @ThongBao = @ThongBao + N'Km tối thiểu phải nhỏ hơn km tối đa. ';
        END
        
        IF @GioMin >= @GioMax
        BEGIN
            SET @IsValid = 0;
            SET @ThongBao = @ThongBao + N'Giờ tối thiểu phải nhỏ hơn giờ tối đa. ';
        END
        
        IF @IsValid = 1
        BEGIN
            SET @ThongBao = N'Tất cả tham số hợp lệ.';
        END
        
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        SET @IsValid = 0;
        SET @ThongBao = N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -999;
    END CATCH
END
GO