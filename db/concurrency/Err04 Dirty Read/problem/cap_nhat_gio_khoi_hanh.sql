USE VNRAILWAY
GO


CREATE or ALTER PROCEDURE sp_CapNhatGioKhoiHanh
    @MaChuyenTau nchar(10),
    @ThoiGianXuatPhatMoi datetime
AS
BEGIN
 
    
    DECLARE @error int = 0
    DECLARE @MaTuyen nchar(4)
    DECLARE @MaGaDi nchar(5)
    DECLARE @ThoiGianCu datetime
    
    BEGIN TRANSACTION
    
    PRINT N'Nhân viên quản lý đang cập nhật giờ khởi hành'
    
    -- B1: Kiểm tra chuyến tàu có tồn tại không
    IF NOT EXISTS (SELECT * FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
    BEGIN
        PRINT N'Lỗi: Chuyến tàu không tồn tại'
        ROLLBACK
        RETURN
    END
    
    -- B2: Lấy thông tin chuyến tàu
    SELECT @MaTuyen = MaTuyen, @ThoiGianCu = ThoiGianXuatPhat
    FROM CHUYEN_TAU
    WHERE MaChuyenTau = @MaChuyenTau
    
    SELECT @MaGaDi = MaGa
    FROM CHUYEN_GA
    WHERE MaChuyenTau = @MaChuyenTau AND TrinhTu = 1
    
    PRINT N' Giờ khởi hành hiện tại: ' + CONVERT(varchar, @ThoiGianCu, 120)
    PRINT N' Giờ khởi hành mới: ' + CONVERT(varchar, @ThoiGianXuatPhatMoi, 120)
    
    -- B3: Cập nhật giờ khởi hành trong bảng CHUYEN_TAU
    UPDATE CHUYEN_TAU
    SET ThoiGianXuatPhat = @ThoiGianXuatPhatMoi
    WHERE MaChuyenTau = @MaChuyenTau
    
    PRINT N'Đã cập nhật giờ khởi hành trong CHUYEN_TAU'
    
    -- B4: Cập nhật giờ đi trong bảng CHUYEN_GA
    UPDATE CHUYEN_GA
    SET ThoiGianDi = @ThoiGianXuatPhatMoi
    WHERE MaChuyenTau = @MaChuyenTau AND TrinhTu = 1
    
    PRINT N' Đã cập nhật giờ đi trong CHUYEN_GA'
    
    -- Chờ 20 giây
    PRINT N'Đang kiểm tra ràng buộc nghiệp vụ...'
    WAITFOR DELAY '00:00:20'
    
    -- B5: Kiểm tra trùng lịch
    PRINT N' Kiểm tra trùng lịch với các chuyến khác...'
    
    IF EXISTS (
        SELECT ct.MaChuyenTau
        FROM CHUYEN_TAU ct
        WHERE ct.MaTuyen = @MaTuyen
        AND ct.ThoiGianXuatPhat = @ThoiGianXuatPhatMoi
        AND ct.MaChuyenTau != @MaChuyenTau
    )
    BEGIN
        PRINT N'LỖI: Phát hiện trùng lịch!'
        PRINT N'ROLLBACK toàn bộ giao dịch'
        ROLLBACK
        RETURN
    END
    
    PRINT N'Không có trùng lịch'
    COMMIT
    PRINT N'COMMIT thành công'
END
GO
  