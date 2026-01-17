USE VNRAILWAY
GO

/* =============================================
   Procedure: usp_CapNhatKhuyenMai
   Mô tả: Cập nhật tỷ lệ giảm giá cho các tham số khuyến mãi.
   Logic mới: 
     - Input: Nhập số từ 0 đến 100 (VD: Nhập 50 nghĩa là 50%)
     - Process: SP tự động chia 100 (50 / 100 = 0.5) để lưu vào DB.
   ============================================= */
CREATE OR ALTER PROC usp_CapNhatKhuyenMai
    @MaThamSo NCHAR(5),
    @GiaTriNhap DECIMAL(12, 2), -- Người dùng nhập 1 đến 100
    @ThongBao NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRAN;
    BEGIN TRY
        -- =============================================
        -- 1. KIỂM TRA PHẠM VI THAM SỐ (WHITELIST)
        -- =============================================
        -- Chỉ cho phép sửa các mã giảm giá (VD: TS009, TS010, TS011)
        IF @MaThamSo NOT IN ('TS009', 'TS010', 'TS011') 
        BEGIN
            SET @ThongBao = N'Mã này không phải là mã khuyến mãi hợp lệ.';
            ROLLBACK TRAN;
            RETURN -1;
        END

        -- =============================================
        -- 2. VALIDATE GIÁ TRỊ NHẬP (0 - 100)
        -- =============================================
        -- Chấp nhận giá trị từ 0 đến 100 (đại diện cho 0% đến 100%)
        IF @GiaTriNhap < 0 OR @GiaTriNhap > 100
        BEGIN
            SET @ThongBao = N'Giá trị nhập phải từ 0 đến 100 (VD: Nhập 20 cho 20%).';
            ROLLBACK TRAN;
            RETURN -3;
        END

        -- =============================================
        -- 3. KIỂM TRA TỒN TẠI & KHÓA (UPDLOCK)
        -- =============================================
        IF NOT EXISTS (
            SELECT 1 
            FROM THAM_SO WITH (UPDLOCK, ROWLOCK) 
            WHERE MaThamSo = @MaThamSo
        )
        BEGIN
            SET @ThongBao = N'Mã tham số không tồn tại.';
            ROLLBACK TRAN;
            RETURN -2;
        END

        -- =============================================
        -- 4. TỰ ĐỘNG CHUYỂN ĐỔI & UPDATE
        -- =============================================
        -- Chuyển từ hệ số 100 về hệ số thập phân (VD: 50 -> 0.50)
        DECLARE @GiaTriLuu DECIMAL(12, 2);
        SET @GiaTriLuu = @GiaTriNhap / 100.0;

        UPDATE THAM_SO
        SET GiaTriThamSo = @GiaTriLuu
        WHERE MaThamSo = @MaThamSo;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @ThongBao = N'Lỗi hệ thống: Không thể cập nhật.';
            ROLLBACK TRAN;
            RETURN -9001;
        END

        COMMIT TRAN;
        SET @ThongBao = N'Cập nhật thành công: ' + 
                        CAST(@GiaTriNhap AS NVARCHAR(20)) + N'% (Đã lưu ' + 
                        CAST(@GiaTriLuu AS NVARCHAR(20)) + N')';
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @ThongBao = N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -9999;
    END CATCH
END
GO