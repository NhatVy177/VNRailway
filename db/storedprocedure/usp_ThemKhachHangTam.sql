CREATE OR ALTER PROC usp_ThemKhachHangTam
    @HoTen      nvarchar(50),
    @CMND       nchar(12),
    @SDT        nchar(10) = NULL,       -- ⭐ Tùy chọn
    @NgSinh     date = NULL,            -- ⭐ Tùy chọn
    @DiaChi     nvarchar(100) = NULL,   -- ⭐ Tùy chọn
    @MaKH       nchar(10) OUTPUT,
    @ThongBao   nvarchar(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- =============================================
        -- 1. VALIDATE SỐ ĐIỆN THOẠI (NẾU CÓ)
        -- =============================================
        IF @SDT IS NOT NULL
        BEGIN
            -- Kiểm tra format: bắt đầu bằng 0, đúng 10 số
            IF @SDT NOT LIKE '0%' OR LEN(@SDT) <> 10 OR ISNUMERIC(@SDT) = 0
            BEGIN
                SET @ThongBao = N'Số điện thoại không hợp lệ (phải 10 số, bắt đầu bằng 0)';
                ROLLBACK TRANSACTION;
                RETURN -1012;
            END
            
            -- Kiểm tra trùng SDT (nếu có UNIQUE constraint)
            IF EXISTS (SELECT 1 FROM NGUOI_DUNG WHERE SDT = @SDT)
            BEGIN
                SET @ThongBao = N'Số điện thoại đã được sử dụng';
                ROLLBACK TRANSACTION;
                RETURN -1013;
            END
        END
        
        -- =============================================
        -- 2. VALIDATE NGÀY SINH (NẾU CÓ)
        -- =============================================
        IF @NgSinh IS NOT NULL AND @NgSinh >= GETDATE()
        BEGIN
            SET @ThongBao = N'Ngày sinh không hợp lệ (phải nhỏ hơn ngày hiện tại)';
            ROLLBACK TRANSACTION;
            RETURN -1014;
        END
        
        -- =============================================
        -- 3. KIỂM TRA CMND ĐÃ TỒN TẠI CHƯA
        -- =============================================
        DECLARE @MaNguoiDung nchar(10);
        
        SELECT @MaNguoiDung = MaNguoiDung
        FROM NGUOI_DUNG
        WHERE CMND = @CMND;
        
        IF @MaNguoiDung IS NOT NULL
        BEGIN
            -- ⭐ ĐÃ TỒN TẠI → Trả về MaKH hiện tại
            
            -- Kiểm tra xem có trong KHACH_HANG chưa
            IF EXISTS (SELECT 1 FROM KHACH_HANG WHERE MaKH = @MaNguoiDung)
            BEGIN
                SET @MaKH = @MaNguoiDung;
                SET @ThongBao = N'Khách hàng đã tồn tại';
                COMMIT TRANSACTION;
                RETURN 0;
            END
            ELSE
            BEGIN
                -- Có trong NGUOI_DUNG nhưng chưa có trong KHACH_HANG
                -- → Thêm vào KHACH_HANG
                INSERT INTO KHACH_HANG (MaKH) VALUES (@MaNguoiDung);
                
                IF @@ERROR <> 0
                BEGIN
                    SET @ThongBao = N'Lỗi khi thêm vào KHACH_HANG';
                    ROLLBACK TRANSACTION;
                    RETURN -9002;
                END
                
                SET @MaKH = @MaNguoiDung;
                SET @ThongBao = N'Đã thêm vào KHACH_HANG';
                COMMIT TRANSACTION;
                RETURN 0;
            END
        END
        
        -- =============================================
        -- 2. CHƯA TỒN TẠI → TẠO MỚI
        -- =============================================
        
        -- Tạo mã mới dạng U000001, U000002,... (U + 6 số)
        DECLARE @SoThuTu int;
        SET @SoThuTu = NEXT VALUE FOR SEQ_MA_KHACH_HANG;
        SET @MaNguoiDung = N'U' + RIGHT(N'000000' + CAST(@SoThuTu AS nvarchar), 6);
        
        -- Insert vào NGUOI_DUNG
        INSERT INTO NGUOI_DUNG (
            MaNguoiDung, 
            HoTen, 
            CMND, 
            NgSinh,      -- ⭐ Có thể NULL hoặc có giá trị
            DiaChi,      -- ⭐ Có thể NULL hoặc có giá trị
            SDT,         -- ⭐ Có thể NULL hoặc có giá trị
            LoaiND
        )
        VALUES (
            @MaNguoiDung,
            @HoTen,
            @CMND,
            @NgSinh,     -- ⭐ Từ parameter
            @DiaChi,     -- ⭐ Từ parameter
            @SDT,        -- ⭐ Từ parameter
            'KH'
        );
        
        IF @@ERROR <> 0
        BEGIN
            SET @ThongBao = N'Lỗi khi tạo NGUOI_DUNG';
            ROLLBACK TRANSACTION;
            RETURN -9001;
        END
        
        -- Insert vào KHACH_HANG
        INSERT INTO KHACH_HANG (MaKH)
        VALUES (@MaNguoiDung);
        
        IF @@ERROR <> 0
        BEGIN
            SET @ThongBao = N'Lỗi khi tạo KHACH_HANG';
            ROLLBACK TRANSACTION;
            RETURN -9002;
        END
        
        COMMIT TRANSACTION;
        
        SET @MaKH = @MaNguoiDung;
        SET @ThongBao = N'Tạo khách hàng tạm thành công: ' + @MaNguoiDung;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ThongBao = N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -9999;
    END CATCH
END
GO