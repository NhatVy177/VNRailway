CREATE OR ALTER FUNCTION dbo.fn_TinhChoTrong_TheoToa
(
    @MaChuyenTau nchar(10),
    @MaToa       nchar(5),
    @MaGaDi      nchar(5),
    @MaGaDen     nchar(5)
)
RETURNS INT
AS
BEGIN
    DECLARE @TongCho INT;
    DECLARE @ChoDaBan INT;

    /* 1. Tổng số chỗ trong toa */
    SELECT @TongCho = COUNT(*)
    FROM VI_TRI_CHO_TRONG
    WHERE MaToa = @MaToa;

    /* 2. Số chỗ đã bán GIAO ĐOẠN (chỉ đếm vé giao với đoạn @MaGaDi → @MaGaDen) */
    ;WITH CTE_TrinhTu AS (
        SELECT
            Di.TrinhTu  AS TrinhTuDi,
            Den.TrinhTu AS TrinhTuDen
        FROM CHUYEN_GA Di
        JOIN CHUYEN_GA Den ON Di.MaChuyenTau = Den.MaChuyenTau
        WHERE Di.MaChuyenTau = @MaChuyenTau
          AND Di.MaGa = @MaGaDi
          AND Den.MaGa = @MaGaDen
    )
    SELECT @ChoDaBan = COUNT(DISTINCT CTV.MaCho)
    FROM CHI_TIET_VE CTV
    JOIN DON_DAT_VE DDV ON CTV.MaDon = DDV.MaDon
    JOIN CTE_TrinhTu T ON 1 = 1
    JOIN CHUYEN_GA DiVe ON DiVe.MaChuyenTau = DDV.MaChuyenTau
                        AND DiVe.MaGa = DDV.MaGaDi
    JOIN CHUYEN_GA DenVe ON DenVe.MaChuyenTau = DDV.MaChuyenTau
                         AND DenVe.MaGa = DDV.MaGaDen
    WHERE DDV.MaChuyenTau = @MaChuyenTau
      AND CTV.MaToa = @MaToa
      AND CTV.TrangThai <> N'Đã hủy'
      -- Giao đoạn: vé [DiVe, DenVe) giao với [@MaGaDi, @MaGaDen)
      AND DiVe.TrinhTu < T.TrinhTuDen
      AND T.TrinhTuDi < DenVe.TrinhTu;

    RETURN ISNULL(@TongCho, 0) - ISNULL(@ChoDaBan, 0);
END;
GO