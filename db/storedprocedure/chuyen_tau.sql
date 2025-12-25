/* Thêm chuyến tàu */
CREATE OR ALTER PROC usp_ThemChuyenTau
	@MaTuyen NCHAR(4),
	@MaDoanTau NCHAR(4),
	@ThoiGianXuatPhat DATETIME,
	@ThongBao NVARCHAR(200) OUT
AS 
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET NOCOUNT ON;

BEGIN TRAN;
	-- 1. Kiểm tra thời gian xuất phát
	IF @ThoiGianXuatPhat <= DATEADD(MONTH, 1, GETDATE())
	BEGIN
		SET @ThongBao = N'Thời gian xuất phát phải sau thời điểm hiện tại ít nhất 1 tháng.';
		ROLLBACK TRAN;
		RETURN -1001;
	END;


	-- 2. Kiểm tra mã tuyến
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


	-- 3. Kiểm tra mã đoàn tàu
	IF NOT EXISTS (
		SELECT 1
		FROM DOAN_TAU
		WHERE MaDoanTau = @MaDoanTau
		)
	BEGIN
		SET @ThongBao = N'Đoàn tàu không tồn tại.';
		ROLLBACK TRAN;
		RETURN -1004;
	END;


	-- 4. Kiểm tra đoàn tàu có thuộc tuyến không
	IF NOT EXISTS (
		SELECT 1
		FROM TUYEN_DOANTAU
		WHERE MaTuyen = @MaTuyen AND MaDoanTau = @MaDoanTau
		)
	BEGIN
		SET @ThongBao = N'Đoàn tàu không thuộc tuyến tương ứng.';
		ROLLBACK TRAN;
		RETURN -1005;
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
		SET @ThongBao = N'Tổng số km mà đoàn tàu được phân công chạy trong tuần tương ứng không được vượt quá ' + CAST(@SoKmToiDa AS NVARCHAR(20)) + N' km.';
        ROLLBACK TRAN;
        RETURN -1006;
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
		SET @ThongBao = N'Đoàn tàu đã được phân công chạy chuyến khác trong khoảng thời gian này.';
		ROLLBACK TRAN;
		RETURN -1008;
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
		SET @ThongBao = N'Lỗi khi thêm chuyến tàu.';
		ROLLBACK TRAN;
		RETURN -9001;
	END;

	INSERT INTO CHUYEN_GA (MaChuyenTau, MaGa, TrinhTu)
        SELECT @MaChuyenTau, MaGa, TrinhTu
        FROM TUYEN_GA
        WHERE MaTuyen = @MaTuyen;

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi thêm ga cho chuyến tàu.';
		ROLLBACK TRAN;
		RETURN -9002;
	END;

COMMIT TRAN;
SET @ThongBao = N'Thêm chuyến tàu thành công.';
RETURN 0;
GO



/* Cập nhật chuyến tàu */
CREATE OR ALTER PROC usp_CapNhatChuyenTau
	@MaChuyenTau NCHAR(10),
	@MaTuyen NCHAR(4),
	@MaDoanTau NCHAR(4),
	@ThoiGianXuatPhat DATETIME,
	@ThongBao NVARCHAR(200) OUT
AS 
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET NOCOUNT ON;

BEGIN TRAN;
	-- 1. Kiểm tra mã chuyến tàu
	IF NOT EXISTS (
		SELECT 1
		FROM CHUYEN_TAU
		WHERE MaChuyenTau = @MaChuyenTau
		)
	BEGIN
		SET @ThongBao = N'Chuyến tàu không tồn tại.';
		ROLLBACK TRAN;
		RETURN -1009;
	END;


	-- 2. Kiểm tra đã có vé đặt cho chuyến tàu này chưa
	IF EXISTS (
		SELECT 1
		FROM DON_DAT_VE
		WHERE MaChuyenTau = @MaChuyenTau
		)
	BEGIN
		SET @ThongBao = N'Không thể cập nhật do đã có vé đặt cho chuyến tàu này.';
		ROLLBACK TRAN;
		RETURN -1010;
	END;


	-- 3. Kiểm tra thời gian xuất phát
	IF @ThoiGianXuatPhat <= DATEADD(WEEK, 1, GETDATE())
	BEGIN
		SET @ThongBao = N'Thời gian xuất phát phải sau thời điểm hiện tại ít nhất 1 tuần.';
		ROLLBACK TRAN;
		RETURN -1002;
	END;


	-- 4. Kiểm tra mã tuyến
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


	-- 5. Kiểm tra mã đoàn tàu
	IF NOT EXISTS (
		SELECT 1
		FROM DOAN_TAU
		WHERE MaDoanTau = @MaDoanTau
		)
	BEGIN
		SET @ThongBao = N'Đoàn tàu không tồn tại.';
		ROLLBACK TRAN;
		RETURN -1004;
	END;


	-- 6. Kiểm tra đoàn tàu có thuộc tuyến không
	IF NOT EXISTS (
		SELECT 1
		FROM TUYEN_DOANTAU
		WHERE MaTuyen = @MaTuyen AND MaDoanTau = @MaDoanTau
		)
	BEGIN
		SET @ThongBao = N'Đoàn tàu không thuộc tuyến tương ứng.';
		ROLLBACK TRAN;
		RETURN -1005;
	END;


	-- 7. Kiểm tra số km mà đoàn tàu này đã được phân công trong tuần đó có vượt mức tối đa không
	-- Lấy thời điểm bắt đầu và kết thúc của tuần đó
	DECLARE @DauTuan DATETIME;
	DECLARE @CuoiTuan DATETIME;

	SELECT @DauTuan = DauTuan, @CuoiTuan = CuoiTuan
	FROM fn_LayTuan(@ThoiGianXuatPhat);

	-- Lấy danh sách chuyến tàu mà đoàn tàu này đã được phân công trong tuần đó (loại trừ chính chuyến đang cập nhật)
	SELECT
		MaChuyenTau,
		MaTuyen
	INTO #ChuyenTrongTuan
	FROM CHUYEN_TAU WITH (UPDLOCK, HOLDLOCK)
	WHERE MaDoanTau = @MaDoanTau
	  AND MaChuyenTau <> @MaChuyenTau
	  AND ThoiGianXuatPhat >= @DauTuan
	  AND ThoiGianXuatPhat < @CuoiTuan;
	
	-- Tính tổng số km mà đoàn tàu này đã được phân công trong tuần đó
	DECLARE @TongKmTrongTuan DECIMAL(6,2);

	SELECT @TongKmTrongTuan = SUM(tg.KhoangCach)
	FROM #ChuyenTrongTuan ch
	JOIN TUYEN_GA tg ON tg.MaTuyen = ch.MaTuyen;
	
	-- Tính tổng số km mới của chuyến đang cần cập nhật
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
		SET @ThongBao = N'Tổng số km mà đoàn tàu được phân công chạy trong tuần tương ứng không được vượt quá ' + CAST(@SoKmToiDa AS NVARCHAR(20)) + N' km.';
        ROLLBACK TRAN;
        RETURN -1006;
    END
	

	-- 8. Kiểm tra thời gian chạy có bị trùng với chuyến khác của cùng đoàn tàu không
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

	-- Thời gian dự kiến đến mới của chuyến cần cập nhật
	DECLARE @ThoiGianDuKienDen DATETIME;
	SET @ThoiGianDuKienDen =
		DATEADD(MINUTE, @TongThoiGianChay + @ThoiGianDung, @ThoiGianXuatPhat);

	-- Kiểm tra trùng giờ
	IF EXISTS (
		SELECT 1
		FROM CHUYEN_TAU
		WHERE MaDoanTau = @MaDoanTau
		  AND MaChuyenTau <> @MaChuyenTau
		  AND @ThoiGianXuatPhat < ThoiGianDuKienDen
		  AND ThoiGianXuatPhat < @ThoiGianDuKienDen	
	)
	BEGIN
		SET @ThongBao = N'Đoàn tàu đã được phân công chạy chuyến khác trong khoảng thời gian này.';
		ROLLBACK TRAN;
		RETURN -1008;
	END;


	-- 9. Cập nhật chuyến tàu
	UPDATE CHUYEN_TAU 
	SET MaTuyen = @MaTuyen, 
		MaDoanTau = @MaDoanTau,
		ThoiGianXuatPhat = @ThoiGianXuatPhat
	WHERE MaChuyenTau = @MaChuyenTau;

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi cập nhật chuyến tàu.';
		ROLLBACK TRAN;
		RETURN -9003;
	END;

	DELETE FROM CHUYEN_GA WHERE MaChuyenTau = @MaChuyenTau;

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi xóa ga cũ của chuyến tàu.';
		ROLLBACK TRAN;
		RETURN -9004;
	END;

	INSERT INTO CHUYEN_GA (MaChuyenTau, MaGa, TrinhTu)
        SELECT @MaChuyenTau, MaGa, TrinhTu
        FROM TUYEN_GA
        WHERE MaTuyen = @MaTuyen;

	IF @@ERROR <> 0
	BEGIN
		SET @ThongBao = N'Lỗi khi thêm ga cho chuyến tàu.';
		ROLLBACK TRAN;
		RETURN -9002;
	END;

COMMIT TRAN;
SET @ThongBao = N'Cập nhật chuyến tàu thành công.';
RETURN 0;
GO	
