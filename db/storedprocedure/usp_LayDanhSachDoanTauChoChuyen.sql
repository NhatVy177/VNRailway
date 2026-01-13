-- Lấy danh sách đoàn tàu thuộc tuyến cho trước mà chưa vượt
-- số km tối đa được phép phân công trong tuần. Dùng khi thêm chuyến tàu.
CREATE OR ALTER PROC usp_LayDanhSachDoanTauChoChuyen
(
    @MaTuyen			NCHAR(4),
    @ThoiDiem			DATETIME,
    @Trang				INT,
    @KichThuocTrang     INT,

    @SoKetQua			INT OUT,
    @ThongBao			NVARCHAR(200) OUT
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SET NOCOUNT ON;
    
    -- 1. Kiểm tra mã tuyến
    IF NOT EXISTS (
        SELECT 1 FROM TUYEN WHERE MaTuyen = @MaTuyen
    )
    BEGIN
        SET @ThongBao = N'Tuyến không tồn tại.';
        RETURN -1003;
    END


    -- 2. Lấy số km tối đa được phép phân công cho mỗi đoàn tàu trong 1 tuần
    DECLARE @SoKmToiDa DECIMAL(12,2);

    SELECT @SoKmToiDa = GiaTriThamSo
    FROM THAM_SO
    WHERE MaThamSo = 'TS015';

    
    -- 3. Tính tổng số kết quả
    SELECT @SoKetQua = COUNT(*)
    FROM DOAN_TAU dt
    JOIN TUYEN_DOANTAU td
        ON dt.MaDoanTau = td.MaDoanTau
    WHERE td.MaTuyen = @MaTuyen
      AND dbo.fn_TinhTongKmDoanTauTrongTuan(dt.MaDoanTau, @ThoiDiem) <= @SoKmToiDa;


    -- 4. Lấy danh sách đoàn tàu thỏa điều kiện
    SELECT
        dt.MaDoanTau,
        dt.TenTau,
        dt.HangSX,
        dt.NgVanHanh,
        dt.LoaiTau,
        TongKmTrongTuan =
            dbo.fn_TinhTongKmDoanTauTrongTuan(dt.MaDoanTau, @ThoiDiem)
    FROM DOAN_TAU dt
    JOIN TUYEN_DOANTAU td
        ON dt.MaDoanTau = td.MaDoanTau
    WHERE td.MaTuyen = @MaTuyen
      AND dbo.fn_TinhTongKmDoanTauTrongTuan(dt.MaDoanTau, @ThoiDiem) <= @SoKmToiDa
    ORDER BY TongKmTrongTuan ASC
    OFFSET (@Trang - 1) * @KichThuocTrang ROWS
    FETCH NEXT @KichThuocTrang ROWS ONLY;

    SET @ThongBao = N'Lấy danh sách đoàn tàu thành công.';
    RETURN 0;
END
GO


--DECLARE @ReturnCode INT;
--DECLARE @ThongBao NVARCHAR(200);
--DECLARE @SoKetQua INT;

--EXEC @ReturnCode = usp_LayDanhSachDoanTauChoChuyen
--    @MaTuyen = N'TN01',
--    @ThoiDiem = '2026-04-15 00:00:00',
--    @Trang = 1,
--    @KichThuocTrang = 10,

--    @SoKetQua = @SoKetQua OUT,
--    @ThongBao = @ThongBao OUT;

--PRINT CONCAT(@ReturnCode, N': ', @ThongBao);
--PRINT CONCAT(N'Số kết quả: ', @SoKetQua);
--GO
