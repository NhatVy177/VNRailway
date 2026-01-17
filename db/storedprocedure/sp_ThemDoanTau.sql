/*
    Stored Procedure: sp_ThemDoanTau
    Mục đích: Thêm đoàn tàu mới
*/
CREATE OR ALTER PROC sp_ThemDoanTau
    @MaDoanTau NCHAR(4),
    @TenTau NVARCHAR(50),
    @HangSX NVARCHAR(50),
    @NgVanHanh DATE,
    @LoaiTau NCHAR(1),
    @ThongBao NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Kiểm tra mã đoàn tàu đã tồn tại
        IF EXISTS (SELECT 1 FROM DOAN_TAU WHERE MaDoanTau = @MaDoanTau)
        BEGIN
            SET @ThongBao = N'Mã đoàn tàu đã tồn tại: ' + @MaDoanTau;
            RETURN -1;
        END
        
        -- Kiểm tra loại tàu hợp lệ
        IF @LoaiTau NOT IN ('S', 'T')
        BEGIN
            SET @ThongBao = N'Loại tàu không hợp lệ. Chỉ chấp nhận S (tàu nhanh) hoặc T (tàu thường)';
            RETURN -2;
        END
        
        -- Kiểm tra ngày vận hành không được trong tương lai
        IF @NgVanHanh > GETDATE()
        BEGIN
            SET @ThongBao = N'Ngày vận hành không được trong tương lai';
            RETURN -3;
        END
        
        -- Thêm đoàn tàu mới
        INSERT INTO DOAN_TAU (MaDoanTau, TenTau, HangSX, NgVanHanh, LoaiTau)
        VALUES (@MaDoanTau, @TenTau, @HangSX, @NgVanHanh, @LoaiTau);
        
        COMMIT TRANSACTION;
        SET @ThongBao = N'✅ Thêm đoàn tàu thành công: ' + @MaDoanTau;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @ThongBao = N'❌ Lỗi: ' + ERROR_MESSAGE();
        RETURN -99;
    END CATCH
END;
GO
