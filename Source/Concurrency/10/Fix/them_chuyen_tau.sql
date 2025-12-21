/* Thêm chuyến tàu */
CREATE OR ALTER PROC usp_ThemChuyenTau
	@MaTuyen NCHAR(4),
	@MaDoanTau NCHAR(4),
	@ThoiGianXuatPhat DATETIME
AS 
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRAN;
	-- 1. Kiểm tra thời gian xuất phát
	IF @ThoiGianXuatPhat <= DATEADD(MONTH, 1, GETDATE())
	BEGIN
		RAISERROR (N'Thời gian xuất phát phải sau thời điểm hiện tại ít nhất 1 tháng.', 16, 1);
		ROLLBACK TRAN;
		RETURN -1;
	END;


	-- 2. Kiểm tra mã tuyến
	IF NOT EXISTS (
		SELECT 1
		FROM TUYEN
		WHERE MaTuyen = @MaTuyen
		)
	BEGIN
		RAISERROR(N'Tuyến không tồn tại.', 16, 1);
		ROLLBACK TRAN;
		RETURN -2;
	END;


	-- 3. Kiểm tra mã đoàn tàu
	IF NOT EXISTS (
		SELECT 1
		FROM DOAN_TAU
		WHERE MaDoanTau = @MaDoanTau
		)
	BEGIN
		RAISERROR(N'Đoàn tàu không tồn tại.', 16, 1);
		ROLLBACK TRAN;
		RETURN -3;
	END;


	-- 4. Kiểm tra đoàn tàu có thuộc tuyến không
	IF NOT EXISTS (
		SELECT 1
		FROM TUYEN_DOANTAU
		WHERE MaTuyen = @MaTuyen AND MaDoanTau = @MaDoanTau
		)
	BEGIN
		RAISERROR(N'Đoàn tàu không thuộc tuyến tương ứng.', 16, 1);
		ROLLBACK TRAN;
		RETURN -4;
	END;


	-- 5. Kiểm tra số km mà đoàn tàu này đã được phân công trong tuần đó có vượt mức tối đa không
	-- Lấy thời điểm bắt đầu và kết thúc của tuần đó
	DECLARE @DauTuan DATETIME;
	DECLARE @CuoiTuan DATETIME;

	SELECT @DauTuan = DauTuan, @CuoiTuan = CuoiTuan
	FROM fn_LayTuan(@ThoiGianXuatPhat);

	-- Lấy danh sách chuyến tàu mà đoàn tàu này đã được phân công trong tuần đó
	SELECT
		MaChuyenTau,
		MaTuyen
	INTO #ChuyenTrongTuan
	FROM CHUYEN_TAU WITH (UPDLOCK, HOLDLOCK)
	WHERE MaDoanTau = @MaDoanTau
	  AND ThoiGianXuatPhat >= @DauTuan
	  AND ThoiGianXuatPhat < @CuoiTuan;
	
	WAITFOR DELAY '00:00:10';

	-- Tính tổng số km mà đoàn tàu này đã được phân công trong tuần đó
	DECLARE @TongKmTrongTuan DECIMAL(6,2);

	SELECT @TongKmTrongTuan = SUM(tg.KhoangCach)
	FROM #ChuyenTrongTuan ch
	JOIN TUYEN_GA tg ON tg.MaTuyen = ch.MaTuyen;
	
	-- Tính tổng số km của chuyến đang cần thêm
	DECLARE @TongKmChuyenMoi DECIMAL(6,2);

	SELECT @TongKmChuyenMoi = SUM(KhoangCach)
	FROM TUYEN_GA
	WHERE MaTuyen = @MaTuyen;

	-- Lấy số km tối đa được phép phân công cho mỗi đoàn tàu trong 1 tuần
	DECLARE @SoKmToiDa DECIMAL(12, 2);

	SELECT @SoKmToiDa = GiaTriThamSo
	FROM THAM_SO
	WHERE MaThamSo = 'TS015';

	-- Kiểm tra vượt mức
	IF (@TongKmTrongTuan + @TongKmChuyenMoi) > @SoKmToiDa
	BEGIN
		DECLARE @ThongBaoVuotMuc NVARCHAR(200);
		SET @ThongBaoVuotMuc = N'Tổng số km mà đoàn tàu được phân công chạy trong tuần tương ứng không được vượt quá ' + CAST(@SoKmToiDa AS NVARCHAR(20)) + N' km.';

		RAISERROR(@ThongBaoVuotMuc, 16, 1);
        ROLLBACK TRAN;
        RETURN -5;
    END;
	

	-- 6. Kiểm tra thời gian chạy có bị trùng với chuyến khác của cùng đoàn tàu không
	-- Tổng thời gian di chuyển giữa các ga (phút)
	DECLARE @TongThoiGianChay INT;

	SELECT @TongThoiGianChay = SUM(DATEDIFF(MINUTE, '00:00:00', TGDiChuyenGiuaCacGa))
	FROM TUYEN_GA
	WHERE MaTuyen = @MaTuyen;

	-- Số ga trên tuyến
	DECLARE @SoGa INT;

	SELECT @SoGa = COUNT(*)
	FROM TUYEN_GA
	WHERE MaTuyen = @MaTuyen;

	-- Tổng thời gian dừng (5 phút cho mỗi ga trung gian)
	DECLARE @ThoiGianDung INT;
	SET @ThoiGianDung = (@SoGa - 2) * 5;

	-- Thời gian dự kiến đến của chuyến cần thêm
	DECLARE @ThoiGianDuKienDen DATETIME;
	SET @ThoiGianDuKienDen =
		DATEADD(MINUTE, @TongThoiGianChay + @ThoiGianDung, @ThoiGianXuatPhat);

	-- Kiểm tra trùng giờ
	IF EXISTS (
		SELECT 1
		FROM CHUYEN_TAU
		WHERE MaDoanTau = @MaDoanTau
		  AND @ThoiGianXuatPhat < ThoiGianDuKienDen
		  AND ThoiGianXuatPhat < @ThoiGianDuKienDen
	)
	BEGIN
		RAISERROR(N'Đoàn tàu đã được phân công chạy chuyến khác trong khoảng thời gian này.', 16, 1);
		ROLLBACK TRAN;
		RETURN -6;
	END;


	-- 7. Tạo mã chuyến tàu
	DECLARE @MaChuyenTau VARCHAR(10);

	SET @MaChuyenTau = 'VNW'
		+ SUBSTRING(
			REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''),
			1, 7
		  );


	-- 8. Thêm chuyến tàu
	INSERT INTO CHUYEN_TAU (MaChuyenTau, MaTuyen, MaDoanTau, ThoiGianXuatPhat) 
	VALUES (@MaChuyenTau, @MaTuyen, @MaDoanTau, @ThoiGianXuatPhat);

	IF @@ERROR <> 0
	BEGIN
		RAISERROR(N'Lỗi khi thêm chuyến tàu.', 16, 1);
		ROLLBACK TRAN;
		RETURN -7;
	END;

	INSERT INTO CHUYEN_GA (MaChuyenTau, MaGa, TrinhTu)
        SELECT @MaChuyenTau, MaGa, TrinhTu
        FROM TUYEN_GA
        WHERE MaTuyen = @MaTuyen;

	IF @@ERROR <> 0
	BEGIN
		RAISERROR(N'Lỗi khi thêm ga cho chuyến tàu.', 16, 1);
		ROLLBACK TRAN;
		RETURN -8;
	END;

COMMIT TRAN;
RETURN 0;
GO

--EXEC usp_ThemChuyenTau N'TN01', N'D030', '2026-04-15 21:00:00';
--GO
