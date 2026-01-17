USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_UpdateThamSo
-- Version: Chấp nhận tỷ lệ giảm giá từ 1-100
-- Tự động convert: 20 → 0.2 (20%)
-- =============================================
CREATE OR ALTER PROC sp_UpdateThamSo
    @MaThamSo NCHAR(5),
    @GiaTriMoi DECIMAL(12, 2),
    @ThongBao NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    
    BEGIN TRY
        -- =============================================
        -- PHASE 1: BASIC VALIDATION
        -- =============================================
        
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
        
        -- =============================================
        -- PHASE 2: CONVERT TỶ LỆ GIẢM GIÁ
        -- =============================================
        
        --  Nếu là tỷ lệ giảm giá (TS009, TS010, TS011)
        -- Chấp nhận input 1-100, tự động chia 100
        IF @MaThamSo IN ('TS009', 'TS010', 'TS011') 
        BEGIN
            -- Validate: Phải từ 1 đến 100
            IF @GiaTriMoi < 1 OR @GiaTriMoi > 100
            BEGIN
                SET @ThongBao = N'Tỷ lệ giảm giá phải từ 1 đến 100 (%).';
                RETURN -3;
            END
            
            -- Convert: 20 → 0.2
            SET @GiaTriMoi = @GiaTriMoi / 100.0;
            
            PRINT N'Converted: ' + CAST(@GiaTriMoi * 100 AS VARCHAR) + N'% → ' + CAST(@GiaTriMoi AS VARCHAR);
        END
        
        -- =============================================
        -- PHASE 3: SPECIFIC VALIDATION + LOCKING
        -- =============================================
        
        -- LOCK tham số liên quan để prevent race condition
        DECLARE @GiaTriLienQuan TABLE (
            MaThamSo NCHAR(5),
            GiaTri DECIMAL(12, 2)
        );
        
        INSERT INTO @GiaTriLienQuan
        SELECT MaThamSo, GiaTriThamSo
        FROM THAM_SO 
        WHERE MaThamSo IN (
            'TS002', 'TS003',  -- Thời gian mở/đóng bán
            'TS014', 'TS015',  -- Km tối thiểu/tối đa
            'TS016', 'TS017'   -- Giờ tối thiểu/tối đa
        );
        
        -- Validate phí đổi vé (0-100)
        IF @MaThamSo = 'TS007'
        BEGIN
            IF @GiaTriMoi < 0 OR @GiaTriMoi > 100
            BEGIN
                SET @ThongBao = N'Phí đổi vé phải từ 0 đến 100%.';
                RETURN -4;
            END
        END
        
        -- =============================================
        -- PHASE 4: CROSS-VALIDATION (với data đã lock)
        -- =============================================
        
        -- TS002: Thời gian mở bán > Thời gian đóng bán
        IF @MaThamSo = 'TS002' 
        BEGIN
            DECLARE @ThoiGianDongBan DECIMAL(12, 2);
            SELECT @ThoiGianDongBan = GiaTri 
            FROM @GiaTriLienQuan 
            WHERE MaThamSo = 'TS003';
            
            IF (@GiaTriMoi * 24 * 60) <= @ThoiGianDongBan
            BEGIN
                SET @ThongBao = N'Thời điểm mở bán phải lớn hơn thời điểm đóng bán.';
                RETURN -5;
            END
        END
        
        -- TS003: Thời gian đóng bán < Thời gian mở bán
        IF @MaThamSo = 'TS003'
        BEGIN
            DECLARE @ThoiGianMoBan DECIMAL(12, 2);
            SELECT @ThoiGianMoBan = GiaTri 
            FROM @GiaTriLienQuan 
            WHERE MaThamSo = 'TS002';
            
            IF @GiaTriMoi >= (@ThoiGianMoBan * 24 * 60)
            BEGIN
                SET @ThongBao = N'Thời điểm đóng bán phải nhỏ hơn thời điểm mở bán.';
                RETURN -6;
            END
        END
        
        -- TS014: Km tối thiểu < Km tối đa
        IF @MaThamSo = 'TS014'
        BEGIN
            DECLARE @KmToiDa DECIMAL(12, 2);
            SELECT @KmToiDa = GiaTri 
            FROM @GiaTriLienQuan 
            WHERE MaThamSo = 'TS015';
            
            IF @GiaTriMoi >= @KmToiDa
            BEGIN
                SET @ThongBao = N'Km tối thiểu phải nhỏ hơn km tối đa.';
                RETURN -7;
            END
        END
        
        -- TS015: Km tối đa > Km tối thiểu
        IF @MaThamSo = 'TS015'
        BEGIN
            DECLARE @KmToiThieu DECIMAL(12, 2);
            SELECT @KmToiThieu = GiaTri 
            FROM @GiaTriLienQuan 
            WHERE MaThamSo = 'TS014';
            
            IF @GiaTriMoi <= @KmToiThieu
            BEGIN
                SET @ThongBao = N'Km tối đa phải lớn hơn km tối thiểu.';
                RETURN -8;
            END
        END
        
        -- TS016: Giờ tối thiểu < Giờ tối đa
        IF @MaThamSo = 'TS016'
        BEGIN
            DECLARE @GioToiDa DECIMAL(12, 2);
            SELECT @GioToiDa = GiaTri 
            FROM @GiaTriLienQuan 
            WHERE MaThamSo = 'TS017';
            
            IF @GiaTriMoi >= @GioToiDa
            BEGIN
                SET @ThongBao = N'Giờ làm việc tối thiểu phải nhỏ hơn giờ tối đa.';
                RETURN -9;
            END
        END
        
        -- TS017: Giờ tối đa > Giờ tối thiểu
        IF @MaThamSo = 'TS017'
        BEGIN
            DECLARE @GioToiThieu DECIMAL(12, 2);
            SELECT @GioToiThieu = GiaTri 
            FROM @GiaTriLienQuan 
            WHERE MaThamSo = 'TS016';
            
            IF @GiaTriMoi <= @GioToiThieu
            BEGIN
                SET @ThongBao = N'Giờ làm việc tối đa phải lớn hơn giờ tối thiểu.';
                RETURN -10;
            END
        END
        
        -- =============================================
        -- PHASE 5: UPDATE
        -- =============================================
        
        UPDATE THAM_SO
        SET GiaTriThamSo = @GiaTriMoi
        WHERE MaThamSo = @MaThamSo;
        
        IF @@ROWCOUNT = 0
        BEGIN
            SET @ThongBao = N'Không thể cập nhật tham số.';
            RETURN -11;
        END
        
        -- SUCCESS
        SET @ThongBao = N'Cập nhật tham số thành công.';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        SET @ThongBao = N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -999;
    END CATCH
END
GO

-- CỬA SỔ 2: Transaction Cập nhật tham số
-- Chạy ngay khi Cửa sổ 1 đang hiện "Executing query..."
DECLARE @ThongBao nvarchar(200);

EXEC sp_UpdateThamSo 
    @MaThamSo = 'TS001', 
    @GiaTriMoi = 6, 
    @ThongBao = @ThongBao OUT;

PRINT N'Cập nhật tham số: ' + @ThongBao;
SELECT * FROM THAM_SO WHERE MaThamSo = 'TS001';



