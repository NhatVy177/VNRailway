CREATE OR ALTER PROC usp_XemDanhSachChuyenTau_fix
    @MaTuyen NCHAR(4)
AS
SET NOCOUNT ON;

-- [GIẢI PHÁP] Nâng mức cô lập lên SERIALIZABLE
-- Mức này sẽ KHÓA chặt phạm vi dữ liệu, ngăn người khác chèn mới
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; 

BEGIN TRAN;
    -- 1. Đọc lần 1
    -- Hệ thống sẽ cấp khóa S (RangeS-S) và GIỮ NÓ
    SELECT MaChuyenTau, MaTuyen, MaDoanTau, ThoiGianXuatPhat 
    FROM CHUYEN_TAU 
    WHERE MaTuyen = @MaTuyen and ThoiGianXuatPhat > Getdate();

    -- 2. Tạo độ trễ
    WAITFOR DELAY '00:00:10';

    -- 3. Đọc lần 2
    -- Dữ liệu vẫn y nguyên như lần 1 vì T2 đã bị chặn (Blocked)
    SELECT MaChuyenTau, MaTuyen, MaDoanTau, ThoiGianXuatPhat 
    FROM CHUYEN_TAU 
    WHERE MaTuyen = @MaTuyen and ThoiGianXuatPhat > Getdate();

COMMIT TRAN; -- Lúc này mới nhả khóa, T2 mới được chạy tiếp
GO
PRINT N'--- BẮT ĐẦU GIAO TÁC 1 ---';
EXEC usp_XemDanhSachChuyenTau_fix @MaTuyen = 'TN01';