USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_UpdateGiaVeCoban
-- Cập nhật giá vé cơ bản theo mã tham số
-- =============================================
CREATE OR ALTER PROC sp_UpdateGiaVeCoban
    @MaThamSo NCHAR(5),
    @GiaCobanMoi DECIMAL(12, 2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate: Kiểm tra tham số có tồn tại và là giá vé
        IF NOT EXISTS (SELECT 1 FROM THAM_SO WHERE MaThamSo = @MaThamSo AND MaThamSo LIKE 'GV%')
        BEGIN
            RAISERROR(N'Mã tham số giá vé không tồn tại.', 16, 1);
            RETURN -1;
        END
        
        -- Validate: Giá trị > 0
        IF @GiaCobanMoi <= 0
        BEGIN
            RAISERROR(N'Giá vé phải lớn hơn 0.', 16, 1);
            RETURN -2;
        END
        
        -- Validate: Giá vé hợp lý (100 - 10,000,000 VNĐ/km)
        IF @GiaCobanMoi < 100 OR @GiaCobanMoi > 10000000
        BEGIN
            RAISERROR(N'Giá vé phải trong khoảng 100 - 10,000,000 VNĐ/km.', 16, 1);
            RETURN -3;
        END
        
        -- Update giá vé
        UPDATE THAM_SO
        SET GiaTriThamSo = @GiaCobanMoi
        WHERE MaThamSo = @MaThamSo;
        
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN -99;
    END CATCH
END
GO
