USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_ValidateThamSo (FIXED VERSION)
-- Kiểm tra tính hợp lệ của giá trị tham số trước khi cập nhật
-- =============================================
CREATE OR ALTER PROC sp_ValidateThamSo
    @MaThamSo NCHAR(5),
    @GiaTriMoi DECIMAL(12, 2),
    @IsValid BIT OUT,
    @ThongBao NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @IsValid = 0;
    
    BEGIN TRY
        -- Kiểm tra tham số có tồn tại
        IF NOT EXISTS (SELECT 1 FROM THAM_SO WHERE MaThamSo = @MaThamSo)
        BEGIN
            SET @ThongBao = N'Mã tham số không tồn tại.';
            RETURN -1;
        END
        
        -- Giá trị > 0
        IF @GiaTriMoi <= 0
        BEGIN
            SET @ThongBao = N'Giá trị phải lớn hơn 0.';
            RETURN -2;
        END
        
        -- Validate: Tỷ lệ giảm giá (%) - lưu dạng thập phân (0.15 = 15%)
        IF @MaThamSo IN ('TS009', 'TS010', 'TS011') 
        BEGIN
            IF @GiaTriMoi < 0 OR @GiaTriMoi > 1
            BEGIN
                SET @ThongBao = N'Tỷ lệ giảm giá phải từ 0 đến 1 (0% - 100%).';
                RETURN -3;
            END
        END
        
        -- Validate: Phí đổi vé (lưu trực tiếp)
        IF @MaThamSo = 'TS007'
        BEGIN
            IF @GiaTriMoi < 0 OR @GiaTriMoi > 100
            BEGIN
                SET @ThongBao = N'Tỷ lệ phí đổi vé phải từ 0 đến 100 (%).';
                RETURN -3;
            END
        END
        
        -- Validate ràng buộc logic
        IF @MaThamSo = 'TS002' 
        BEGIN
            DECLARE @ThoiGianDongBan1 DECIMAL(12, 2);
            SELECT @ThoiGianDongBan1 = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS003';
            
            IF (@GiaTriMoi * 24 * 60) <= @ThoiGianDongBan1
            BEGIN
                SET @ThongBao = N'Thời điểm mở bán phải lớn hơn thời điểm đóng bán.';
                RETURN -4;
            END
        END
        
        IF @MaThamSo = 'TS003'
        BEGIN
            DECLARE @ThoiGianMoBan1 DECIMAL(12, 2);
            SELECT @ThoiGianMoBan1 = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS002';
            
            IF @GiaTriMoi >= (@ThoiGianMoBan1 * 24 * 60)
            BEGIN
                SET @ThongBao = N'Thời điểm đóng bán phải nhỏ hơn thời điểm mở bán.';
                RETURN -5;
            END
        END
        
        IF @MaThamSo = 'TS014'
        BEGIN
            DECLARE @KmToiDa1 DECIMAL(12, 2);
            SELECT @KmToiDa1 = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS015';
            
            IF @GiaTriMoi >= @KmToiDa1
            BEGIN
                SET @ThongBao = N'Km tối thiểu phải nhỏ hơn km tối đa.';
                RETURN -6;
            END
        END
        
        IF @MaThamSo = 'TS015'
        BEGIN
            DECLARE @KmToiThieu1 DECIMAL(12, 2);
            SELECT @KmToiThieu1 = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS014';
            
            IF @GiaTriMoi <= @KmToiThieu1
            BEGIN
                SET @ThongBao = N'Km tối đa phải lớn hơn km tối thiểu.';
                RETURN -7;
            END
        END
        
        IF @MaThamSo = 'TS016'
        BEGIN
            DECLARE @GioToiDa1 DECIMAL(12, 2);
            SELECT @GioToiDa1 = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS017';
            
            IF @GiaTriMoi >= @GioToiDa1
            BEGIN
                SET @ThongBao = N'Giờ làm việc tối thiểu phải nhỏ hơn giờ tối đa.';
                RETURN -8;
            END
        END
        
        IF @MaThamSo = 'TS017'
        BEGIN
            DECLARE @GioToiThieu1 DECIMAL(12, 2);
            SELECT @GioToiThieu1 = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS016';
            
            IF @GiaTriMoi <= @GioToiThieu1
            BEGIN
                SET @ThongBao = N'Giờ làm việc tối đa phải lớn hơn giờ tối thiểu.';
                RETURN -9;
            END
        END
        
        -- Nếu qua tất cả các kiểm tra
        SET @IsValid = 1;
        SET @ThongBao = N'Giá trị hợp lệ.';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        SET @ThongBao = N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -999;
    END CATCH
END
GO