USE VNRAILWAY
GO

CREATE OR ALTER PROC usp_PhanCongToaTau_Deadlock
    @MaChuyenTau NCHAR(10),
    @VaiTro NVARCHAR(20),      -- "Trưởng toa" hoặc "Nhân viên"
    @MaToa NCHAR(5),
    @MaNhanVien NCHAR(10),
    @MaNVQL NCHAR(10),         -- Có thể NULL
    @ThongBao NVARCHAR(200) OUT
AS
-- =============================================
-- 1. THIẾT LẬP MÔI TRƯỜNG GÂY DEADLOCK
-- =============================================
-- REPEATABLE READ: Giữ Shared Lock (S) sau khi đọc cho đến khi Commit/Rollback.
-- Đây là nguyên nhân chính gây deadlock khi cố chuyển sang Update (X Lock).
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET NOCOUNT ON;

BEGIN TRAN;
BEGIN TRY
    -- =============================================
    -- 2. VALIDATION CƠ BẢN (Giữ nguyên từ bản gốc)
    -- =============================================
    
    -- Kiểm tra chuyến tàu
    IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
    BEGIN
        SET @ThongBao = N'Chuyến tàu không tồn tại.';
        ROLLBACK TRAN; RETURN -1009;
    END

    -- Kiểm tra toa tàu thuộc chuyến
    IF NOT EXISTS (
        SELECT 1 FROM TOA_TAU tt JOIN CHUYEN_TAU ct ON tt.MaDoanTau = ct.MaDoanTau
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

    -- Tự động gán vai trò nếu thiếu
    IF @VaiTro IS NULL OR LTRIM(RTRIM(@VaiTro)) = ''
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM PHANCONG_TOA WHERE MaChuyenTau = @MaChuyenTau AND VaiTro = N'Trưởng toa')
            SET @VaiTro = N'Trưởng toa';
        ELSE
            SET @VaiTro = N'Nhân viên';
    END

    -- =============================================
    -- 3. KIỂM TRA TRÙNG LỊCH (DOUBLE BOOKING) - MỚI BỔ SUNG
    -- =============================================
    -- Lấy thời gian chạy của chuyến tàu hiện tại
    DECLARE @GioDi DATETIME, @GioDen DATETIME;
    SELECT @GioDi = ThoiGianXuatPhat, @GioDen = ThoiGianDuKienDen 
    FROM CHUYEN_TAU 
    WHERE MaChuyenTau = @MaChuyenTau;

    -- Kiểm tra xem nhân viên này có đang "Thực hiện" nhiệm vụ trên chuyến khác
    -- mà thời gian bị chồng lấn (Overlap) không.
    -- Công thức Overlap: (StartA <= EndB) AND (EndA >= StartB)
    IF EXISTS (
        SELECT 1
        FROM PHANCONG_TOA pc
        JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
        WHERE pc.MaNV = @MaNhanVien
          AND pc.MaChuyenTau <> @MaChuyenTau -- Không tính chính chuyến này
          AND pc.TrangThai = N'Thực hiện'      -- Chỉ tính lịch đang hiệu lực
          AND (ct.ThoiGianXuatPhat <= @GioDen AND ct.ThoiGianDuKienDen >= @GioDi) -- Trùng giờ
    )
    BEGIN
        SET @ThongBao = N'Lỗi: Nhân viên đang bận chạy chuyến khác trong khung giờ này.';
        ROLLBACK TRAN; RETURN -1099;
    END

    -- =============================================
    -- 4. KỊCH BẢN GÂY DEADLOCK (Check-Wait-Act)
    -- =============================================
    
    DECLARE @DaPhanCong BIT = 0;

    -- [READ]: Lệnh này sẽ xin Shared Lock (S) trên dòng dữ liệu trong PHANCONG_TOA
    -- Do REPEATABLE READ, khóa S này được GIỮ CHẶT, không nhả ra.
    IF EXISTS (
        SELECT 1 
        FROM PHANCONG_TOA 
        WHERE MaChuyenTau = @MaChuyenTau 
          AND MaToa = @MaToa 
          AND VaiTro = @VaiTro
    )
    BEGIN
        SET @DaPhanCong = 1;
    END

    -- ⚠️ [TRAP]: Dừng 10 giây để chờ Transaction thứ 2 cũng chạy đến đây
    -- Lúc này: T1 giữ khóa S. T2 cũng giữ khóa S. Cả hai cùng "ôm" khóa đọc.
    WAITFOR DELAY '00:00:10';

    -- [WRITE]: Thực hiện Update/Insert
    -- Để ghi, cần xin Exclusive Lock (X).
    -- T1 chờ T2 nhả S để lấy X. T2 chờ T1 nhả S để lấy X.
    -- => DEADLOCK.
    IF @DaPhanCong = 1
    BEGIN
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
        INSERT INTO PHANCONG_TOA (MaNV, MaChuyenTau, VaiTro, TrangThai, MaNVQL, MaToa)
        VALUES (@MaNhanVien, @MaChuyenTau, @VaiTro, N'Thực hiện', @MaNVQL, @MaToa);
    END

    COMMIT TRAN;
    SET @ThongBao = N'Phân công toa tàu thành công.';
    RETURN 0;

END TRY
BEGIN CATCH
    -- Xử lý lỗi
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    
    -- Bắt mã lỗi 1205 (Deadlock)
    IF ERROR_NUMBER() = 1205
    BEGIN
        SET @ThongBao = N'DEADLOCK: Giao dịch bị hủy do tranh chấp tài nguyên với quản lý khác.';
        -- Có thể Return code đặc biệt để App biết mà Retry
        RETURN -1205; 
    END
    ELSE
    BEGIN
        SET @ThongBao = N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -9999;
    END
END CATCH
GO

DECLARE @ThongBao NVARCHAR(200);
DECLARE @Ret INT;

PRINT N'T1: Bắt đầu...';
EXEC @Ret = usp_PhanCongToaTau_Deadlock
    @MaChuyenTau = 'VNW5B64972',
    @VaiTro = N'Nhân viên',
    @MaToa = 'T0098',
    @MaNhanVien = 'U010439', -- Thay người mới
    @MaNVQL = 'U010005',
    @ThongBao = @ThongBao OUT;

PRINT N'T1 Kết quả: ' + @ThongBao;

USE VNRAILWAY
GO

-- 1. Xóa sạch dữ liệu cũ liên quan đến test case này
DELETE FROM PHANCONG_TOA 
WHERE MaChuyenTau = 'VNW5B64972' AND MaToa = 'T0098';

-- 2. Chèn 1 dòng dữ liệu "Mồi" chuẩn xác
-- Lưu ý: VaiTro là 'Trưởng toa' (có dấu, chính xác từng ký tự)
INSERT INTO PHANCONG_TOA (MaNV, MaChuyenTau, VaiTro, TrangThai, MaNVQL, MaToa)
VALUES ('U010217', 'VNW5B64972', N'Nhân viên', N'Thực hiện', 'U010010', 'T0098');

PRINT N'Đã Reset dữ liệu. Dòng phân công cho NV001 đang tồn tại.';
-- Kiểm tra lại
SELECT * FROM PHANCONG_TOA WHERE MaChuyenTau = 'VNW5B64972' AND MaToa = 'T0098';