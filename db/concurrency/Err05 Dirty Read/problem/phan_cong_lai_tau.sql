USE VNRAILWAY
GO

/* =============================================
   Procedure: usp_PhanCongLaiTau_DirtyDemo
   Mô tả: Giống hệt SP gốc (có đủ Validate) nhưng Rollback ở cuối.
   Mục đích: Tạo dữ liệu "bẩn" hợp lệ về mặt logic nhưng không được lưu.
   ============================================= */
CREATE OR ALTER PROC usp_PhanCongLaiTau_DirtyDemo
    @MaChuyenTau NCHAR(10),
    @VaiTro      NVARCHAR(10),
    @MaNhanVien  NCHAR(10),
    @MaNVQL      NCHAR(10),
    @ThongBao    NVARCHAR(200) OUT
AS
BEGIN
    -- Vẫn dùng Read Committed để đảm bảo tính chuẩn xác khi ghi
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SET NOCOUNT ON;

    BEGIN TRAN;
    BEGIN TRY
        -- =============================================
        -- PHẦN 1: GIỮ NGUYÊN TOÀN BỘ VALIDATE CỦA BẠN
        -- =============================================

        -- 1. Kiểm tra chuyến tàu tồn tại
        IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
        BEGIN
            SET @ThongBao = N'Chuyến tàu không tồn tại.';
            ROLLBACK TRAN; RETURN -1009;
        END

        -- 2. Kiểm tra nhân viên tồn tại
        IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNhanVien)
        BEGIN
            SET @ThongBao = N'Nhân viên không tồn tại.';
            ROLLBACK TRAN; RETURN -1026;
        END

        -- 3. Kiểm tra nhân viên là lái tàu
        DECLARE @ChucVu NCHAR(2);
        SELECT @ChucVu = ChucVu FROM NHAN_VIEN WHERE MaNV = @MaNhanVien;

        IF @ChucVu <> N'LT'
        BEGIN
            SET @ThongBao = N'Nhân viên không phải lái tàu.';
            ROLLBACK TRAN; RETURN -1027;
        END

        -- 4. Kiểm tra quản lý tồn tại
        IF @MaNVQL IS NOT NULL AND @MaNVQL <> ''
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNVQL)
            BEGIN
                SET @ThongBao = N'Mã quản lý không tồn tại.';
                ROLLBACK TRAN; RETURN -1028;
            END
        END

        -- =============================================
        -- PHẦN 2: THỰC HIỆN GHI DỮ LIỆU (UPSERT)
        -- =============================================
        
        IF EXISTS (
            SELECT 1 FROM PHANCONG_LAITAU 
            WHERE MaChuyenTau = @MaChuyenTau AND VaiTro = @VaiTro
        )
        BEGIN
            -- UPDATE
            UPDATE PHANCONG_LAITAU
            SET MaNV = @MaNhanVien,
                TrangThai = N'Thực hiện',
                MaNVQL = @MaNVQL
            WHERE MaChuyenTau = @MaChuyenTau AND VaiTro = @VaiTro;
        END
        ELSE
        BEGIN
            -- INSERT
            INSERT INTO PHANCONG_LAITAU (MaNV, MaChuyenTau, VaiTro, TrangThai, MaNVQL)
            VALUES (@MaNhanVien, @MaChuyenTau, @VaiTro, N'Thực hiện', @MaNVQL);
        END

        -- =============================================
        -- PHẦN 3: GÀI BẪY (DIRTY WINDOW)
        -- =============================================
        
        -- Dừng 10 giây. Trong lúc này, dữ liệu ĐÃ ĐƯỢC GHI vào bảng
        -- và ĐÃ VƯỢT QUA tất cả các bước kiểm tra (Validate) ở trên.
        -- Nhưng nó chưa được Commit.
        WAITFOR DELAY '00:00:10';

        -- Hủy bỏ phút chót (Giả lập lỗi hệ thống hoặc user hủy)
        ROLLBACK TRAN; 
        
        SET @ThongBao = N'Demo Dirty Read: Thao tác hợp lệ nhưng đã bị Rollback.';
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
EXEC usp_PhanCongLaiTau_DirtyDemo 
    @MaChuyenTau = 'VNW035AED5',  -- Thay bằng mã thật
    @VaiTro      = N'Lái chính', 
    @MaNhanVien  = 'U010114   ',       -- Thay bằng mã NV lái tàu thật
    @MaNVQL      = 'U010010', 
    @ThongBao    = @ThongBao OUT;

PRINT @ThongBao;

