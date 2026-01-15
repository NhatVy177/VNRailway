USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_PhanCongLaiTau (CORRECT VERSION)
-- Dựa trên cấu trúc bảng thực tế:
-- PHANCONG_LAITAU (MaNV, MaChuyenTau, VaiTro, TrangThai, MaNVQL)
-- =============================================
CREATE OR ALTER PROC usp_PhanCongLaiTau
    @MaChuyenTau NCHAR(10),
    @VaiTro NVARCHAR(10),
    @MaNhanVien NCHAR(10),
    @MaNVQL NCHAR(10),
    @ThongBao NVARCHAR(200) OUT
AS
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET NOCOUNT ON;

BEGIN TRAN;
BEGIN TRY
    -- 1. Kiểm tra chuyến tàu tồn tại
    IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
    BEGIN
        SET @ThongBao = N'Chuyến tàu không tồn tại.';
        ROLLBACK TRAN;
        RETURN -1009;
    END

    -- 2. Kiểm tra nhân viên tồn tại
    IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNhanVien)
    BEGIN
        SET @ThongBao = N'Nhân viên không tồn tại.';
        ROLLBACK TRAN;
        RETURN -1026;
    END

    -- 3. Kiểm tra nhân viên là lái tàu
    DECLARE @ChucVu NCHAR(2);
    SELECT @ChucVu = ChucVu
    FROM NHAN_VIEN
    WHERE MaNV = @MaNhanVien;

    IF @ChucVu <> N'LT'
    BEGIN
        SET @ThongBao = N'Nhân viên không phải lái tàu.';
        ROLLBACK TRAN;
        RETURN -1027;
    END

    -- 4. Kiểm tra quản lý tồn tại (nếu không NULL)
    IF @MaNVQL IS NOT NULL AND @MaNVQL <> ''
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNVQL)
        BEGIN
            SET @ThongBao = N'Mã quản lý không tồn tại.';
            ROLLBACK TRAN;
            RETURN -1028;
        END
    END

    -- 5. Xử lý UPSERT (Update nếu có, Insert nếu chưa có)
    -- Giả sử PRIMARY KEY là (MaNV, MaChuyenTau) hoặc (MaChuyenTau, VaiTro)
    
    -- Kiểm tra đã có phân công cho vai trò này chưa
    IF EXISTS (
        SELECT 1 
        FROM PHANCONG_LAITAU 
        WHERE MaChuyenTau = @MaChuyenTau 
          AND VaiTro = @VaiTro
    )
    BEGIN
        -- ✅ Đã có → UPDATE
        UPDATE PHANCONG_LAITAU
        SET MaNV = @MaNhanVien,
            TrangThai = N'Thực hiện',
            MaNVQL = @MaNVQL
        WHERE MaChuyenTau = @MaChuyenTau 
          AND VaiTro = @VaiTro;

        COMMIT TRAN;
        SET @ThongBao = N'Cập nhật phân công lái tàu thành công.';
        RETURN 0;
    END
    ELSE
    BEGIN
        -- ✅ Chưa có → INSERT
        INSERT INTO PHANCONG_LAITAU (
            MaNV, 
            MaChuyenTau, 
            VaiTro, 
            TrangThai, 
            MaNVQL
        )
        VALUES (
            @MaNhanVien, 
            @MaChuyenTau, 
            @VaiTro, 
            N'Thực hiện', 
            @MaNVQL
        );

        COMMIT TRAN;
        SET @ThongBao = N'Phân công lái tàu thành công.';
        RETURN 0;
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    
    -- Error message chi tiết
    DECLARE @ErrorMsg NVARCHAR(500);
    SET @ErrorMsg = N'Lỗi: ' + ERROR_MESSAGE() + 
                    N' (Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + N')';
    
    -- Log để debug
    PRINT @ErrorMsg;
    
    SET @ThongBao = @ErrorMsg;
    RETURN -9007;
END CATCH
GO