/* Xóa tuyến */
CREATE OR ALTER PROC usp_11_fix_XoaTuyen
	@MaTuyen NCHAR(4),
	@MaNVThucHien NCHAR(10),
	@ThongBao NVARCHAR(200) OUT
AS
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET NOCOUNT ON;

BEGIN TRAN;
	-- 1. Kiểm tra tuyến tồn tại
	IF NOT EXISTS (
		SELECT 1
		FROM TUYEN
		WHERE MaTuyen = @MaTuyen
	)
	BEGIN
		SET @ThongBao = N'Tuyến không tồn tại.';
		ROLLBACK TRAN;
		RETURN -1003;
	END;


	-- 2. Kiểm tra nhân viên thực hiện tồn tại
	IF NOT EXISTS (
		SELECT 1
		FROM NHAN_VIEN
		WHERE MaNV = @MaNVThucHien
	)
	BEGIN
		SET @ThongBao = N'Nhân viên không tồn tại.';
		ROLLBACK TRAN;
		RETURN -1011;
	END;


	-- 3. Kiểm tra nhân viên thực hiện có quyền quản lý tuyến này không
	IF NOT EXISTS (
		SELECT 1
		FROM TUYEN
		WHERE MaTuyen = @MaTuyen
		  AND MaNVQL = @MaNVThucHien
	)
	BEGIN
		SET @ThongBao = N'Tuyến không thuộc quyền quản lý của nhân viên này.';
		ROLLBACK TRAN;
		RETURN -1012;
	END;

	
	-- 4. Kiểm tra có tồn tại chuyến thuộc tuyến này không
	IF EXISTS (
		SELECT 1
		FROM CHUYEN_TAU
		WHERE MaTuyen = @MaTuyen
	)
	BEGIN
		SET @ThongBao = N'Không thể xóa do tồn tại chuyến thuộc tuyến này.';
		ROLLBACK TRAN;
		RETURN -1022;
	END;


	-- 5. Xóa các liên kết đoàn tàu với tuyến
	DELETE FROM TUYEN_DOANTAU
	WHERE MaTuyen = @MaTuyen;

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi xóa liên kết tuyến - đoàn tàu.';
		ROLLBACK TRAN;
		RETURN -9203;
	END;


	WAITFOR DELAY '00:00:10';


	-- 6. Xóa danh sách ga của tuyến
	DELETE FROM TUYEN_GA
	WHERE MaTuyen = @MaTuyen;

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi xóa danh sách ga của tuyến.';
		ROLLBACK TRAN;
		RETURN -9202;
	END;


	-- 7. Xóa tuyến
	DELETE FROM TUYEN
	WHERE MaTuyen = @MaTuyen;

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi xóa tuyến.';
		ROLLBACK TRAN;
		RETURN -9204;
	END;

COMMIT TRAN;
SET @ThongBao = N'Xóa tuyến thành công.';
RETURN 0;
GO


--DECLARE @ReturnCode INT;
--DECLARE @ThongBao NVARCHAR(200);
--EXEC @ReturnCode = usp_11_fix_XoaTuyen N'TN07', N'U010007', @ThongBao OUT;
--PRINT CONCAT(@ReturnCode, N': ', @ThongBao);
--GO
