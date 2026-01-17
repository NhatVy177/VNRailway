CREATE OR ALTER PROC usp_XemDanhSachChuyenTau
    @MaTuyen NCHAR(4)
AS
SET NOCOUNT ON;

-- QUAN TRỌNG: Mức cô lập Read Committed cho phép lỗi Phantom Read xảy ra
SET TRANSACTION ISOLATION LEVEL READ COMMITTED; 

BEGIN TRAN;
	IF EXISTS (SELECT * FROM TUYEN WHERE MaTuyen = @MaTuyen) 
	BEGIN 
		PRINT N'Tuyến tồn tại' 
	END

    -- 1. Đọc lần 1: Lấy danh sách chuyến tàu hiện tại
    PRINT N'--- BẮT ĐẦU ĐỌC LẦN 1 ---';
    SELECT MaChuyenTau, MaTuyen, MaDoanTau, ThoiGianXuatPhat 
    FROM CHUYEN_TAU 
    WHERE MaTuyen = @MaTuyen;

    -- 2. Tạo độ trễ: Dừng lại 10 giây
    -- Mục đích: Để Giao tác 2 có thời gian chen vào thêm chuyến tàu mới
    PRINT N'--- Đang xử lý... (Đợi 10 giây để bên kia Insert) ---';
    WAITFOR DELAY '00:00:10';

    -- 3. Đọc lần 2: Đọc lại danh sách
    -- Kết quả: Sẽ thấy xuất hiện thêm dòng dữ liệu mới (Bóng ma)
    PRINT N'--- ĐỌC LẦN 2 (SẼ THẤY BÓNG MA NẾU CÓ LỖI) ---';
    SELECT MaChuyenTau as machuyen, MaTuyen, MaDoanTau, ThoiGianXuatPhat 
    FROM CHUYEN_TAU 
    WHERE MaTuyen = @MaTuyen;

COMMIT TRAN;
GO

EXEC usp_XemDanhSachChuyenTau 'TN01'

