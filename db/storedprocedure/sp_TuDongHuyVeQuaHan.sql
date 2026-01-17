USE VNRAILWAY
GO

CREATE OR ALTER PROC sp_TuDongHuyVeQuaHan
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Lấy thời gian thanh toán từ tham số (đơn vị: phút)
        DECLARE @ThoiGianTTOnline int = 15;      -- Mặc định 15 phút
        DECLARE @ThoiGianTTTrucTiep int = 180;   -- Mặc định 180 phút (3 giờ)
        
        SELECT @ThoiGianTTOnline = CAST(GiaTriThamSo AS int)
        FROM THAM_SO
        WHERE MaThamSo = 'TS004'; -- Thời gian thanh toán online (phút)
        
        SELECT @ThoiGianTTTrucTiep = CAST(GiaTriThamSo AS int)
        FROM THAM_SO
        WHERE MaThamSo = 'TS005'; -- Thời gian thanh toán trực tiếp (phút)
        
        -- Đếm số vé sẽ bị hủy
        DECLARE @SoVeHuy int = 0;
        
        SELECT @SoVeHuy = COUNT(*)
        FROM CHI_TIET_VE v
        INNER JOIN DON_DAT_VE d ON v.MaDon = d.MaDon
        WHERE v.TrangThai = N'Chưa thanh toán'
            AND v.ThoiGianXuatVe IS NULL
            AND (
                -- Thanh toán chuyển khoản (online): quá 15 phút
                (v.PhuongThucTT = N'Chuyển khoản' 
                 AND d.ThoiGianDatve < DATEADD(MINUTE, -@ThoiGianTTOnline, GETDATE()))
                OR
                -- Thanh toán tiền mặt (trực tiếp): quá 180 phút
                (v.PhuongThucTT = N'Tiền mặt' 
                 AND d.ThoiGianDatve < DATEADD(MINUTE, -@ThoiGianTTTrucTiep, GETDATE()))
            );
        
        -- Hủy các vé chưa thanh toán quá hạn
        UPDATE CHI_TIET_VE
        SET TrangThai = N'Đã hủy',
            ThoiGianXuatVe = GETDATE()
        FROM CHI_TIET_VE v
        INNER JOIN DON_DAT_VE d ON v.MaDon = d.MaDon
        WHERE v.TrangThai = N'Chưa thanh toán'
            AND v.ThoiGianXuatVe IS NULL
            AND (
                -- Thanh toán chuyển khoản (online): quá 15 phút
                (v.PhuongThucTT = N'Chuyển khoản' 
                 AND d.ThoiGianDatve < DATEADD(MINUTE, -@ThoiGianTTOnline, GETDATE()))
                OR
                -- Thanh toán tiền mặt (trực tiếp): quá 180 phút
                (v.PhuongThucTT = N'Tiền mặt' 
                 AND d.ThoiGianDatve < DATEADD(MINUTE, -@ThoiGianTTTrucTiep, GETDATE()))
            );
        
        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT N'Lỗi khi cập nhật trạng thái vé';
            RETURN -1;
        END
        
        COMMIT TRANSACTION;
        
        -- Log kết quả
        PRINT N'Đã tự động hủy ' + CAST(@SoVeHuy AS nvarchar(10)) + N' vé quá hạn thanh toán';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -9999;
    END CATCH
END
GO
