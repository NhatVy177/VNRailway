USE VNRAILWAY
GO

/* =============================================
   Procedure: usp_PhanCongLaiTau_BlockingDemo
   Mô tả: Phiên bản CHUẨN (Commit dữ liệu) nhưng có DELAY
   Mục đích: Minh họa Blocking (SP Đọc sẽ phải xếp hàng chờ SP này chạy xong)
   ============================================= */
CREATE OR ALTER PROC usp_PhanCongLaiTau_BlockingDemo
    @MaChuyenTau NCHAR(10),
    @VaiTro      NVARCHAR(10),
    @MaNhanVien  NCHAR(10),
    @MaNVQL      NCHAR(10),
    @ThongBao    NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;
    -- Mức cô lập chuẩn
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRAN;
    BEGIN TRY
        -- =============================================
        -- 1. VALIDATION
        -- =============================================
        
        -- Kiểm tra chuyến tàu
        IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
        BEGIN
            SET @ThongBao = N'Chuyến tàu không tồn tại.';
            ROLLBACK TRAN; RETURN -1009;
        END

        -- Kiểm tra nhân viên
        IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNhanVien)
        BEGIN
            SET @ThongBao = N'Nhân viên không tồn tại.';
            ROLLBACK TRAN; RETURN -1026;
        END

        -- Kiểm tra chức vụ
        DECLARE @ChucVu NCHAR(2);
        SELECT @ChucVu = ChucVu FROM NHAN_VIEN WHERE MaNV = @MaNhanVien;

        IF @ChucVu <> N'LT'
        BEGIN
            SET @ThongBao = N'Nhân viên không phải lái tàu.';
            ROLLBACK TRAN; RETURN -1027;
        END

        -- Kiểm tra quản lý
        IF @MaNVQL IS NOT NULL AND @MaNVQL <> ''
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNVQL)
            BEGIN
                SET @ThongBao = N'Mã quản lý không tồn tại.';
                ROLLBACK TRAN; RETURN -1028;
            END
        END

        -- =============================================
        -- 2. THỰC HIỆN GHI (UPSERT)
        -- =============================================
        
        IF EXISTS (SELECT 1 FROM PHANCONG_LAITAU WHERE MaChuyenTau = @MaChuyenTau AND VaiTro = @VaiTro)
        BEGIN
            UPDATE PHANCONG_LAITAU
            SET MaNV = @MaNhanVien,
                TrangThai = N'Thực hiện',
                MaNVQL = @MaNVQL
            WHERE MaChuyenTau = @MaChuyenTau AND VaiTro = @VaiTro;
        END
        ELSE
        BEGIN
            INSERT INTO PHANCONG_LAITAU (MaNV, MaChuyenTau, VaiTro, TrangThai, MaNVQL)
            VALUES (@MaNhanVien, @MaChuyenTau, @VaiTro, N'Thực hiện', @MaNVQL);
        END

        -- =============================================
        -- 3. DELAY (GIỮ KHÓA) - DEMO BLOCKING
        -- =============================================
        
        -- Dừng 10 giây để giữ khóa X trên bảng.
        -- Lúc này, SP Thống kê (Read Committed) sẽ bị TREO (Waiting) tại đây.
        WAITFOR DELAY '00:00:10';

        -- COMMIT: Lưu dữ liệu thành công
        COMMIT TRAN;
        
        SET @ThongBao = N'Phân công thành công (Sau khi delay 10s).';
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @ThongBao = N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -9999;
    END CATCH
END
GO
DECLARE @ThongBao NVARCHAR(200);

PRINT N'Bắt đầu phân công (Đang validate & ghi... Sẽ Rollback sau 10s)';

-- PHẢI DÙNG DỮ LIỆU ĐÚNG:
-- 1. Mã chuyến tàu phải có thật
-- 2. Mã nhân viên phải có thật và chức vụ là 'LT' (Lái tàu)
EXEC usp_PhanCongLaiTau_BlockingDemo
    @MaChuyenTau = 'VNW035AED5',  -- Thay bằng mã thật
    @VaiTro      = N'Lái chính', 
    @MaNhanVien  = 'U010144',       -- Thay bằng mã NV lái tàu thật
    @MaNVQL      = 'U010010', 
    @ThongBao    = @ThongBao OUT;

PRINT @ThongBao;