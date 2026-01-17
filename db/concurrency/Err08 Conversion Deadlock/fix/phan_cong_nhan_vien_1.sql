USE VNRAILWAY
GO

CREATE OR ALTER PROC usp_PhanCongToaTau_FIXED
    @MaChuyenTau NCHAR(10),
    @VaiTro      NVARCHAR(20),      -- "Trưởng toa" hoặc "Nhân viên"
    @MaToa       NCHAR(5),
    @MaNhanVien  NCHAR(10),
    @MaNVQL      NCHAR(10),         -- Có thể NULL
    @ThongBao    NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Dùng READ COMMITTED là đủ vì đã có UPDLOCK bảo vệ logic tranh chấp
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- =============================================
        -- 1. VALIDATION CƠ BẢN (Kiểm tra dữ liệu đầu vào)
        -- =============================================
        
        -- Kiểm tra chuyến tàu tồn tại
        IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
        BEGIN
            SET @ThongBao = N'Chuyến tàu không tồn tại.';
            ROLLBACK TRAN; RETURN -1009;
        END

        -- Kiểm tra toa tàu có thuộc đoàn tàu của chuyến này không
        IF NOT EXISTS (
            SELECT 1 
            FROM TOA_TAU tt 
            JOIN CHUYEN_TAU ct ON tt.MaDoanTau = ct.MaDoanTau
            WHERE ct.MaChuyenTau = @MaChuyenTau AND tt.MaToa = @MaToa
        )
        BEGIN
            SET @ThongBao = N'Toa tàu không thuộc chuyến này.';
            ROLLBACK TRAN; RETURN -1030;
        END

        -- Kiểm tra chức vụ nhân viên (Phải là Trực tàu - TT)
        DECLARE @ChucVu NCHAR(2);
        SELECT @ChucVu = ChucVu FROM NHAN_VIEN WHERE MaNV = @MaNhanVien;

        IF @ChucVu <> N'TT'
        BEGIN
            SET @ThongBao = N'Nhân viên không thuộc bộ phận trực tàu.';
            ROLLBACK TRAN; RETURN -1027;
        END

        -- Kiểm tra người quản lý (nếu có nhập)
        IF @MaNVQL IS NOT NULL AND @MaNVQL <> ''
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNVQL)
            BEGIN
                SET @ThongBao = N'Mã quản lý không tồn tại.';
                ROLLBACK TRAN; RETURN -1028;
            END
        END

        -- Tự động gán vai trò nếu thiếu
        IF @VaiTro IS NULL OR LTRIM(RTRIM(@VaiTro)) = ''
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM PHANCONG_TOA 
                WHERE MaChuyenTau = @MaChuyenTau AND VaiTro = N'Trưởng toa'
            )
                SET @VaiTro = N'Trưởng toa';
            ELSE
                SET @VaiTro = N'Nhân viên';
        END

        -- =============================================
        -- 2. KIỂM TRA LOGIC NGHIỆP VỤ (Chống trùng lịch)
        -- =============================================
        DECLARE @GioDi DATETIME, @GioDen DATETIME;
        SELECT @GioDi = ThoiGianXuatPhat, @GioDen = ThoiGianDuKienDen 
        FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau;

        IF EXISTS (
            SELECT 1
            FROM PHANCONG_TOA pc
            JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
            WHERE pc.MaNV = @MaNhanVien
              AND pc.MaChuyenTau <> @MaChuyenTau
              AND pc.TrangThai = N'Thực hiện'
              AND (ct.ThoiGianXuatPhat < @GioDen AND ct.ThoiGianDuKienDen > @GioDi)
        )
        BEGIN
            SET @ThongBao = N'Lỗi: Nhân viên đang có lịch chạy chuyến khác trong cùng khung giờ.';
            ROLLBACK TRAN; RETURN -1099;
        END

        -- =============================================
        -- 3. XỬ LÝ PHÂN CÔNG (Lõi chống Deadlock)
        -- =============================================
        
        DECLARE @TonTai BIT = 0;

        -- GIẢI PHÁP: WITH (UPDLOCK, ROWLOCK)
        -- Khóa U được cấp ngay khi đọc. Transaction khác cũng muốn xin khóa U sẽ phải CHỜ (Blocking).
        IF EXISTS (
            SELECT 1 
            FROM PHANCONG_TOA WITH (UPDLOCK, ROWLOCK) 
            WHERE MaChuyenTau = @MaChuyenTau 
              AND MaToa = @MaToa 
              AND VaiTro = @VaiTro
        )
        BEGIN
            SET @TonTai = 1;
        END

        -- WAITFOR DELAY: Chỉ dùng để Test Blocking
        -- Transaction 1 sẽ giữ khóa U trong 10 giây.
        -- Transaction 2 chạy vào lúc này sẽ bị treo ở dòng SELECT trên.
        WAITFOR DELAY '00:00:10'; 

        IF @TonTai = 1
        BEGIN
            -- UPDATE: An toàn tuyệt đối vì đã giữ khóa U
            UPDATE PHANCONG_TOA
            SET MaNV = @MaNhanVien,
                TrangThai = N'Thực hiện',
                MaNVQL = @MaNVQL
            WHERE MaChuyenTau = @MaChuyenTau 
              AND MaToa = @MaToa
              AND VaiTro = @VaiTro;
        END
        ELSE
        BEGIN
            -- INSERT
            INSERT INTO PHANCONG_TOA (MaNV, MaChuyenTau, VaiTro, TrangThai, MaNVQL, MaToa)
            VALUES (@MaNhanVien, @MaChuyenTau, @VaiTro, N'Thực hiện', @MaNVQL, @MaToa);
        END

        COMMIT TRAN;
        SET @ThongBao = N'Phân công toa tàu thành công.';
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        
        IF ERROR_NUMBER() = 1205
        BEGIN
            SET @ThongBao = N'Hệ thống đang bận, vui lòng thử lại.';
            RETURN -1205;
        END
        
        SET @ThongBao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        RETURN -9999;
    END CATCH
END
GO

DECLARE @ThongBao NVARCHAR(200);
DECLARE @Ret INT;

PRINT N'T1: Bắt đầu...';
EXEC @Ret = usp_PhanCongToaTau_FIXED
    @MaChuyenTau = 'VNW5B64972',
    @VaiTro = N'Nhân viên',
    @MaToa = 'T0098',
    @MaNhanVien = 'U010439', -- Thay người mới
    @MaNVQL = 'U010005',
    @ThongBao = @ThongBao OUT;

PRINT N'T1 Kết quả: ' + @ThongBao;

