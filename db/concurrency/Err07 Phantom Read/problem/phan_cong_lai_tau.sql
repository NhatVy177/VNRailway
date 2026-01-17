USE VNRAILWAY
GO

CREATE OR ALTER PROC usp_PhanCongLaiTau_PhantomInsert
    @MaChuyenTau NCHAR(10),
    @VaiTro      NVARCHAR(10),
    @MaNhanVien  NCHAR(10),
    @MaNVQL      NCHAR(10),
    @ThongBao    NVARCHAR(200) OUT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SET NOCOUNT ON;

    BEGIN TRAN;
    BEGIN TRY
        -- =============================================
        -- PHẦN 1: GIỮ NGUYÊN VALIDATE CỦA BẠN
        -- =============================================
        IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
        BEGIN
            SET @ThongBao = N'Chuyến tàu không tồn tại.'; ROLLBACK TRAN; RETURN -1;
        END

        IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNhanVien)
        BEGIN
            SET @ThongBao = N'Nhân viên không tồn tại.'; ROLLBACK TRAN; RETURN -2;
        END

        DECLARE @ChucVu NCHAR(2);
        SELECT @ChucVu = ChucVu FROM NHAN_VIEN WHERE MaNV = @MaNhanVien;
        IF @ChucVu <> N'LT'
        BEGIN
            SET @ThongBao = N'Nhân viên không phải lái tàu.'; ROLLBACK TRAN; RETURN -3;
        END

        -- =============================================
        -- PHẦN 2: THỰC HIỆN GHI VÀ COMMIT THẬT
        -- =============================================
        
        -- Xóa phân công cũ (nếu có) để Insert mới cho sạch demo
        DELETE FROM PHANCONG_LAITAU WHERE MaChuyenTau = @MaChuyenTau AND VaiTro = @VaiTro;

        INSERT INTO PHANCONG_LAITAU (MaNV, MaChuyenTau, VaiTro, TrangThai, MaNVQL)
        VALUES (@MaNhanVien, @MaChuyenTau, @VaiTro, N'Thực hiện', @MaNVQL);

        --  QUAN TRỌNG: COMMIT NGAY LẬP TỨC
        COMMIT TRAN; 
        
        SET @ThongBao = N'Đã phân công và COMMIT thành công.';
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
EXEC usp_PhanCongLaiTau_PhantomInsert 
    @MaChuyenTau = 'VNW5B64972',  -- Thay bằng mã thật
    @VaiTro      = N'Lái chính', 
    @MaNhanVien  = 'U010114   ',       -- Thay bằng mã NV lái tàu thật
    @MaNVQL      = 'U010010', 
    @ThongBao    = @ThongBao OUT;

PRINT @ThongBao;