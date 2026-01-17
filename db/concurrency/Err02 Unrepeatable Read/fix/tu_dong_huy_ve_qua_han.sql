USE VNRAILWAY
GO

/* =============================================
   PROCEDURE: sp_TuDongHuyVeQuaHan
   Mô tả: Tự động hủy vé chưa thanh toán quá hạn 15 phút
          Sử dụng READ COMMITTED (mặc định)
   ============================================= */
CREATE OR ALTER PROCEDURE sp_TuDongHuyVeQuaHan
AS
BEGIN
    SET NOCOUNT ON;
    
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- B1: Lấy thời gian thanh toán từ tham số hệ thống
        DECLARE @ThoiGianTT INT = 15;
        
        SELECT @ThoiGianTT = CAST(GiaTriThamSo AS INT)
        FROM THAM_SO
        WHERE MaThamSo = 'TS004';

        -- B2: Đếm số vé sẽ hủy
        DECLARE @SoVeHuy INT;
        
        SELECT @SoVeHuy = COUNT(*)
        FROM CHI_TIET_VE v
        INNER JOIN DON_DAT_VE d ON v.MaDon = d.MaDon
        WHERE v.TrangThai = N'Chưa thanh toán'
          AND v.PhuongThucTT = N'Chuyển khoản'
          AND d.ThoiGianDatve < DATEADD(MINUTE, -@ThoiGianTT, GETDATE());

        PRINT N'>>> Số vé sẽ hủy: ' + CAST(@SoVeHuy AS NVARCHAR(10));

        -- B3: Hủy vé quá hạn
        UPDATE CHI_TIET_VE
        SET TrangThai = N'Đã hủy',
            ThoiGianXuatVe = GETDATE()
        FROM CHI_TIET_VE v
        INNER JOIN DON_DAT_VE d ON v.MaDon = d.MaDon
        WHERE v.TrangThai = N'Chưa thanh toán'
          AND v.PhuongThucTT = N'Chuyển khoản'
          AND d.ThoiGianDatve < DATEADD(MINUTE, -@ThoiGianTT, GETDATE());

        COMMIT TRANSACTION;
        
        PRINT N'>>>  Đã hủy ' + CAST(@SoVeHuy AS NVARCHAR(10)) + N' vé quá hạn thành công!';
        RETURN @SoVeHuy;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH
END
GO

-- Test thực thi
PRINT N'=== T2: Bắt đầu hủy vé quá hạn ===';
EXEC sp_TuDongHuyVeQuaHan;