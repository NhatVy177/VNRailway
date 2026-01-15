-- Lấy danh sách tuyến (kèm tổng số km)
CREATE OR ALTER PROC usp_LayDanhSachTuyen
(
    @Trang              INT,
    @KichThuocTrang     INT,

    @SoKetQua           INT OUT,
    @ThongBao           NVARCHAR(200) OUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SET NOCOUNT ON;

    -- 1. Tính tổng số kết quả
    SELECT @SoKetQua = COUNT(*)
    FROM TUYEN;

    -- 2. Lấy danh sách tuyến + tổng km
    SELECT
        t.MaTuyen,
        t.TenTuyen,
        TongSoKm = ISNULL(SUM(tg.KhoangCach), 0)
    FROM TUYEN t
    LEFT JOIN TUYEN_GA tg
        ON t.MaTuyen = tg.MaTuyen
    GROUP BY
        t.MaTuyen,
        t.TenTuyen
    ORDER BY
        t.MaTuyen ASC
    OFFSET (@Trang - 1) * @KichThuocTrang ROWS
    FETCH NEXT @KichThuocTrang ROWS ONLY;

    SET @ThongBao = N'Lấy danh sách tuyến thành công.';
    RETURN 0;
END
GO


--DECLARE @ReturnCode INT;
--DECLARE @ThongBao NVARCHAR(200);
--DECLARE @SoKetQua INT;

--EXEC @ReturnCode = usp_LayDanhSachTuyen
--    @Trang = 1,
--    @KichThuocTrang = 10,

--    @SoKetQua = @SoKetQua OUT,
--    @ThongBao = @ThongBao OUT;

--PRINT CONCAT(@ReturnCode, N': ', @ThongBao);
--PRINT CONCAT(N'Số kết quả: ', @SoKetQua);
--GO