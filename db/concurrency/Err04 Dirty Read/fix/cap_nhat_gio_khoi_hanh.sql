USE VNRAILWAY
GO


CREATE OR ALTER PROCEDURE sp_CapNhatGioKhoiHanh
    @MaChuyenTau nchar(10),
    @ThoiGianXuatPhatMoi datetime
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaTuyen nchar(4)
    DECLARE @MaGaDi nchar(5)
    DECLARE @ThoiGianCu datetime
    
    -- SỬ DỤNG READ COMMITTED (mặc định)
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    
    BEGIN TRANSACTION
    

    PRINT N'Nhân viên quản lý đang cập nhật giờ khởi hành cho chuyến ' + @MaChuyenTau
    
    BEGIN TRY
        -- B1: Kiểm tra chuyến tàu có tồn tại không
        PRINT N'B1: Kiểm tra chuyến tàu...'
        IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
        BEGIN
            PRINT N'Lỗi: Chuyến tàu không tồn tại'
            ROLLBACK
            RETURN
        END
        PRINT N'Chuyến tàu tồn tại'
        
        -- B2: Lấy thông tin chuyến tàu hiện tại
        PRINT N'Lấy thông tin chuyến tàu...'
        SELECT @MaTuyen = MaTuyen, @ThoiGianCu = ThoiGianXuatPhat
        FROM CHUYEN_TAU
        WHERE MaChuyenTau = @MaChuyenTau
        
        PRINT N'Tuyến: ' + @MaTuyen
        PRINT N'Giờ khởi hành hiện tại: ' + CONVERT(varchar, @ThoiGianCu, 120)
        PRINT N'Giờ khởi hành mới: ' + CONVERT(varchar, @ThoiGianXuatPhatMoi, 120)
        
        -- B3: Cập nhật giờ khởi hành trong bảng CHUYEN_TAU
        PRINT N'B3: Cập nhật giờ khởi hành...'
        UPDATE CHUYEN_TAU
        SET ThoiGianXuatPhat = @ThoiGianXuatPhatMoi
        WHERE MaChuyenTau = @MaChuyenTau
        
        
        -- B4: Cập nhật giờ đi trong bảng CHUYEN_GA (ga đầu tiên)
        SELECT TOP 1 @MaGaDi = MaGa
        FROM CHUYEN_GA
        WHERE MaChuyenTau = @MaChuyenTau
        ORDER BY TrinhTu
        
        UPDATE CHUYEN_GA
        SET ThoiGianDi = @ThoiGianXuatPhatMoi
        WHERE MaChuyenTau = @MaChuyenTau AND MaGa = @MaGaDi
        
        WAITFOR DELAY '00:00:15'
        
        -- B5: Kiểm tra trùng lịch 
        IF EXISTS (
            SELECT 1
            FROM CHUYEN_TAU ct
            WHERE ct.MaTuyen = @MaTuyen
              AND ct.ThoiGianXuatPhat = @ThoiGianXuatPhatMoi
              AND ct.MaChuyenTau != @MaChuyenTau
        )
        BEGIN
            PRINT N'LỖI: Phát hiện trùng lịch!'
            PRINT N'Chuyến tàu khác đã có giờ khởi hành: ' + CONVERT(varchar, @ThoiGianXuatPhatMoi, 120)
            PRINT N'ROLLBACK toàn bộ giao dịch!'
            ROLLBACK
            RETURN
        END
        
        -- Nếu không trùng lịch thì COMMIT
        PRINT N'Không có trùng lịch'
        COMMIT
        PRINT N'COMMIT thành công'
        
    END TRY
    BEGIN CATCH
        PRINT N'Lỗi: ' + ERROR_MESSAGE()
        IF @@TRANCOUNT > 0
            ROLLBACK
    END CATCH
END
GO