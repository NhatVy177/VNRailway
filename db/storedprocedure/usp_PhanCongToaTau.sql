CREATE OR ALTER PROC usp_PhanCongToaTau
    @MaChuyenTau NCHAR(10),
    @VaiTro NVARCHAR(20),      -- "Trưởng toa" hoặc "Nhân viên"
    @MaToa NCHAR(5),
    @MaNhanVien NCHAR(10),
    @MaNVQL NCHAR(10),
    @ThongBao NVARCHAR(200) OUT
AS
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET NOCOUNT ON;

BEGIN TRAN;
BEGIN TRY
    -- 1. Kiểm tra chuyến tàu
    IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
    BEGIN
        SET @ThongBao = N'Chuyến tàu không tồn tại.';
        ROLLBACK TRAN;
        RETURN -1009;
    END

    -- 2. Kiểm tra toa tàu
    IF NOT EXISTS (
        SELECT 1 
        FROM TOA_TAU tt
        JOIN CHUYEN_TAU ct ON tt.MaDoanTau = ct.MaDoanTau
        WHERE ct.MaChuyenTau = @MaChuyenTau AND tt.MaToa = @MaToa
    )
    BEGIN
        SET @ThongBao = N'Toa tàu không thuộc chuyến này.';
        ROLLBACK TRAN;
        RETURN -1030;
    END

    -- 3. Kiểm tra nhân viên
    DECLARE @ChucVu NCHAR(2);
    SELECT @ChucVu = ChucVu
    FROM NHAN_VIEN
    WHERE MaNV = @MaNhanVien;

    IF @ChucVu <> N'TT'
    BEGIN
        SET @ThongBao = N'Nhân viên không thuộc toa tàu.';
        ROLLBACK TRAN;
        RETURN -1027;
    END

    -- 4. Kiểm tra quản lý
    IF @MaNVQL IS NOT NULL AND @MaNVQL <> ''
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNVQL)
        BEGIN
            SET @ThongBao = N'Mã quản lý không tồn tại.';
            ROLLBACK TRAN;
            RETURN -1028;
        END
    END

    -- 5. Xác định vai trò nếu không truyền vào
    IF @VaiTro IS NULL OR LTRIM(RTRIM(@VaiTro)) = ''
    BEGIN
        -- Nếu chưa có Trưởng toa → Phân công làm Trưởng toa
        IF NOT EXISTS (
            SELECT 1 
            FROM PHANCONG_TOA 
            WHERE MaChuyenTau = @MaChuyenTau 
              AND VaiTro = N'Trưởng toa'
        )
        BEGIN
            SET @VaiTro = N'Trưởng toa';
        END
        ELSE
        BEGIN
            SET @VaiTro = N'Nhân viên';
        END
    END

    -- 6. UPSERT: Kiểm tra đã phân công chưa
    IF EXISTS (
        SELECT 1 
        FROM PHANCONG_TOA 
        WHERE MaChuyenTau = @MaChuyenTau 
          AND MaToa = @MaToa
          AND VaiTro = @VaiTro
    )
    BEGIN
        -- Đã có → UPDATE
        UPDATE PHANCONG_TOA
        SET MaNV = @MaNhanVien,
            TrangThai = N'Thực hiện',
            MaNVQL = @MaNVQL
        WHERE MaChuyenTau = @MaChuyenTau 
          AND MaToa = @MaToa
          AND VaiTro = @VaiTro;

        COMMIT TRAN;
        SET @ThongBao = N'Cập nhật phân công toa tàu thành công.';
        RETURN 0;
    END
    ELSE
    BEGIN
        -- Chưa có → INSERT
        INSERT INTO PHANCONG_TOA (
            MaNV, 
            MaChuyenTau, 
            VaiTro, 
            TrangThai, 
            MaNVQL, 
            MaToa
        )
        VALUES (
            @MaNhanVien, 
            @MaChuyenTau, 
            @VaiTro, 
            N'Thực hiện', 
            @MaNVQL, 
            @MaToa
        );

        COMMIT TRAN;
        SET @ThongBao = N'Phân công toa tàu thành công.';
        RETURN 0;
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    
    DECLARE @ErrorMsg NVARCHAR(500);
    SET @ErrorMsg = N'Lỗi: ' + ERROR_MESSAGE() + 
                    N' (Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + N')';
    
    PRINT @ErrorMsg;
    SET @ThongBao = @ErrorMsg;
    RETURN -9007;
END CATCH
GO