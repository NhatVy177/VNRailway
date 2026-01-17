/*
    Stored Procedure: sp_CapNhatDoanTau
    Mục đích: Cập nhật thông tin đoàn tàu
*/
CREATE OR ALTER PROC sp_CapNhatDoanTau
    @MaDoanTau NCHAR(4),
    @TenTau NVARCHAR(50) = NULL,
    @HangSX NVARCHAR(50) = NULL,
    @NgVanHanh DATE = NULL,
    @LoaiTau NCHAR(1) = NULL,
    @ThongBao NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Kiểm tra đoàn tàu có tồn tại
        IF NOT EXISTS (SELECT 1 FROM DOAN_TAU WHERE MaDoanTau = @MaDoanTau)
        BEGIN
            SET @ThongBao = N'Không tìm thấy đoàn tàu: ' + @MaDoanTau;
            RETURN -1;
        END
        
        -- Kiểm tra loại tàu hợp lệ (nếu được cập nhật)
        IF @LoaiTau IS NOT NULL AND @LoaiTau NOT IN ('S', 'T')
        BEGIN
            SET @ThongBao = N'Loại tàu không hợp lệ. Chỉ chấp nhận S (tàu nhanh) hoặc T (tàu thường)';
            RETURN -2;
        END
        
        -- Kiểm tra ngày vận hành không được trong tương lai (nếu được cập nhật)
        IF @NgVanHanh IS NOT NULL AND @NgVanHanh > GETDATE()
        BEGIN
            SET @ThongBao = N'Ngày vận hành không được trong tương lai';
            RETURN -3;
        END
        
        -- Cập nhật thông tin
        UPDATE DOAN_TAU
        SET 
            TenTau = ISNULL(@TenTau, TenTau),
            HangSX = ISNULL(@HangSX, HangSX),
            NgVanHanh = ISNULL(@NgVanHanh, NgVanHanh),
            LoaiTau = ISNULL(@LoaiTau, LoaiTau)
        WHERE MaDoanTau = @MaDoanTau;
        
        COMMIT TRANSACTION;
        SET @ThongBao = N'✅ Cập nhật thông tin đoàn tàu thành công: ' + @MaDoanTau;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @ThongBao = N'❌ Lỗi: ' + ERROR_MESSAGE();
        RETURN -99;
    END CATCH
END;
GO
