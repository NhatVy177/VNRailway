-- Lấy tổng số km đoàn tàu đã được phân công trong tuần
CREATE OR ALTER FUNCTION fn_TinhTongKmDoanTauTrongTuan
(
    @MaDoanTau NCHAR(4),
    @ThoiDiem DATETIME
)
RETURNS DECIMAL(6,2)
AS
BEGIN
    DECLARE @DauTuan DATETIME;
    DECLARE @CuoiTuan DATETIME;
    DECLARE @TongKmTrongTuan DECIMAL(6,2);

    -- Lấy thời điểm đầu và cuối tuần
    SELECT 
        @DauTuan = DauTuan,
        @CuoiTuan = CuoiTuan
    FROM fn_LayTuan(@ThoiDiem);

    -- Tính tổng km các chuyến tàu của đoàn tàu đó trong tuần
    SELECT 
        @TongKmTrongTuan = SUM(tg.KhoangCach)
    FROM CHUYEN_TAU ct
    JOIN TUYEN_GA tg 
        ON tg.MaTuyen = ct.MaTuyen
    WHERE ct.MaDoanTau = @MaDoanTau
      AND ct.ThoiGianXuatPhat >= @DauTuan
      AND ct.ThoiGianXuatPhat <  @CuoiTuan;

    RETURN ISNULL(@TongKmTrongTuan, 0);
END
GO

--SELECT dbo.fn_TinhTongKmDoanTauTrongTuan(N'D030','2026-04-15 00:00:00');

