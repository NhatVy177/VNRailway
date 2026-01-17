/* Cập nhật tuyến */
CREATE OR ALTER PROC usp_11_fix_CapNhatTuyen
	@MaTuyen NCHAR(4),
	@TenTuyen NVARCHAR(50),
	@DanhSachGa dbo.TVP_DanhSachGaTrongTuyen READONLY,
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


	-- 2. Kiểm tra có tồn tại chuyến chưa kết thúc nhưng đã có đơn đặt vé thuộc tuyến này không
	IF EXISTS (
		SELECT 1
		FROM CHUYEN_TAU ct
		WHERE ct.MaTuyen = @MaTuyen
		  AND ct.ThoiGianDuKienDen > GETDATE()
		  AND EXISTS (
			  SELECT 1
			  FROM DON_DAT_VE dv
			  WHERE dv.MaChuyenTau = ct.MaChuyenTau
		  )
	)
	BEGIN
		SET @ThongBao = N'Không thể cập nhật do đang tồn tại chuyến thuộc tuyến này chưa kết thúc nhưng đã có đơn đặt vé.';
		ROLLBACK TRAN;
		RETURN -1013;
	END;


	-- 3. Kiểm tra tên tuyến có rỗng không
	IF LTRIM(RTRIM(@TenTuyen)) = ''
	BEGIN
		SET @ThongBao = N'Tên tuyến không được rỗng.';
		ROLLBACK TRAN;
		RETURN -1014;
	END;

	
	-- 4. Kiểm tra ga tồn tại
	IF EXISTS (
		SELECT 1
		FROM @DanhSachGa ds
		WHERE NOT EXISTS (
			SELECT 1
			FROM GA g
			WHERE g.MaGa = ds.MaGa
		)
	)
	BEGIN
		SET @ThongBao = N'Danh sách ga chứa ga không tồn tại.';
		ROLLBACK TRAN;
		RETURN -1015;
	END;


	-- 5. Kiểm tra ga bị trùng
	IF EXISTS (
		SELECT MaGa
		FROM @DanhSachGa
		GROUP BY MaGa
		HAVING COUNT(*) > 1
	)
	BEGIN
		SET @ThongBao = N'Mỗi ga chỉ được xuất hiện một lần trong danh sách ga.';
		ROLLBACK TRAN;
		RETURN -1016;
	END;


	-- 6. Kiểm tra trình tự của ga có là số dương không
	IF EXISTS (
		SELECT 1 
		FROM @DanhSachGa 
		WHERE TrinhTu < 1
	)
	BEGIN
		SET @ThongBao = N'Trình tự của ga phải là số dương.';
		ROLLBACK TRAN;
		RETURN -1017;
	END;


	-- 7. Kiểm tra trình tự của ga bị trùng
	IF EXISTS (
		SELECT TrinhTu
		FROM @DanhSachGa
		GROUP BY TrinhTu
		HAVING COUNT(*) > 1
	)
	BEGIN
		SET @ThongBao = N'Danh sách ga chứa các ga bị trùng trình tự.';
		ROLLBACK TRAN;
		RETURN -1018;
	END;


	-- 8. Kiểm tra khoảng cách giữa các ga có là số không âm không
	IF EXISTS (
		SELECT 1
		FROM @DanhSachGa
		WHERE KhoangCach < 0
	)
	BEGIN
		SET @ThongBao = N'Khoảng cách giữa các ga phải là số không âm.';
		ROLLBACK TRAN;
		RETURN -1019;
	END;


	-- 9. Kiểm tra ga đầu phải có thời gian di chuyển đến và khoảng cách bằng 0
	-- Lấy thời gian di chuyển đến và khoảng cách
	DECLARE @TGDiChuyenDenGaDau TIME;
	DECLARE @KhoangCachDenGaDau DECIMAL(6,2);

	SELECT 
		@TGDiChuyenDenGaDau = TGDiChuyenGiuaCacGa,
		@KhoangCachDenGaDau = KhoangCach
	FROM @DanhSachGa
	WHERE TrinhTu = 1;

	-- Kiểm tra thời gian di chuyển đến bằng 0
	IF @TGDiChuyenDenGaDau <> '00:00:00'
	BEGIN
		SET @ThongBao = N'Ga đầu của tuyến phải có thời gian di chuyển đến bằng 0.';
		ROLLBACK TRAN;
		RETURN -1020;
	END;

	-- Kiểm tra khoảng cách bằng 0
	IF @KhoangCachDenGaDau <> 0
	BEGIN
		SET @ThongBao = N'Ga đầu của tuyến phải có khoảng cách bằng 0.';
		ROLLBACK TRAN;
		RETURN -1021;
	END;


	WAITFOR DELAY '00:00:10';


	-- 10. Cập nhật danh sách ga của tuyến
	-- Xóa danh sách ga cũ của tuyến
	DELETE FROM TUYEN_GA
	WHERE MaTuyen = @MaTuyen;

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi xóa danh sách ga cũ của tuyến.';
		ROLLBACK TRAN;
		RETURN -9202;
	END;


	WAITFOR DELAY '00:00:10';


	-- Thêm danh sách ga mới cho tuyến
	INSERT INTO TUYEN_GA (
		MaTuyen,
		MaGa,
		TrinhTu,
		TGDiChuyenGiuaCacGa,
		KhoangCach
	)
	SELECT
		@MaTuyen,
		MaGa,
		TrinhTu,
		TGDiChuyenGiuaCacGa,
		KhoangCach
	FROM @DanhSachGa;

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi thêm danh sách ga cho tuyến.';
		ROLLBACK TRAN;
		RETURN -9003;
	END;


	-- 11. Cập nhật danh sách ga của chuyến thuộc tuyến
	-- Lấy danh sách chuyến cần được cập nhật thuộc tuyến này (là chuyến chưa kết thúc và cũng chưa có đơn đặt vé)
	SELECT MaChuyenTau
	INTO #ChuyenCanCapNhat
	FROM CHUYEN_TAU ct
	WHERE ct.MaTuyen = @MaTuyen
	  AND ct.ThoiGianDuKienDen > GETDATE()
	  AND NOT EXISTS (
		  SELECT 1
		  FROM DON_DAT_VE dv
		  WHERE dv.MaChuyenTau = ct.MaChuyenTau
	  );
	
	-- Xóa danh sách ga cũ của các chuyến cần cập nhật
	DELETE cg
	FROM CHUYEN_GA AS cg
	WHERE EXISTS (
		SELECT 1
		FROM #ChuyenCanCapNhat AS c
		WHERE c.MaChuyenTau = cg.MaChuyenTau
	);

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi xóa danh sách ga cũ của chuyến chưa kết thúc và cũng chưa có đơn đặt vé thuộc tuyến.';
		ROLLBACK TRAN;
		RETURN -9201;
	END;

	-- Thêm danh sách ga mới cho các chuyến cần cập nhật
	INSERT INTO CHUYEN_GA (MaChuyenTau, MaGa, TrinhTu)
	SELECT c.MaChuyenTau, tg.MaGa, tg.TrinhTu
	FROM #ChuyenCanCapNhat c JOIN TUYEN_GA tg ON tg.MaTuyen = @MaTuyen;
	
	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi thêm danh sách ga cho chuyến chưa kết thúc và cũng chưa có đơn đặt vé thuộc tuyến.';
		ROLLBACK TRAN;
		RETURN -9002;
	END;


	-- 12. Cập nhật thông tin tuyến
	UPDATE TUYEN
	SET TenTuyen = @TenTuyen
	WHERE MaTuyen = @MaTuyen;

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi cập nhật tuyến.';
		ROLLBACK TRAN;
		RETURN -9102;
	END;

COMMIT TRAN;
SET @ThongBao = N'Cập nhật tuyến thành công.';
RETURN 0;
GO


--DECLARE @ReturnCode INT;
--DECLARE @ThongBao NVARCHAR(200);

--DECLARE @DanhSachGa dbo.TVP_DanhSachGaTrongTuyen;
--INSERT INTO @DanhSachGa (MaGa, TrinhTu, TGDiChuyenGiuaCacGa, KhoangCach)
--VALUES
--    (N'GA012', 1, '00:00:00', 0),
--    (N'GA010', 2, '00:50:00', 43),
--    (N'GA009', 3, '00:45:00', 40);

--EXEC @ReturnCode = usp_11_fix_CapNhatTuyen N'TN16', N'Hải Phòng – Hà Nội', @DanhSachGa , @ThongBao OUT;
--PRINT CONCAT(@ReturnCode, N': ', @ThongBao);
--GO