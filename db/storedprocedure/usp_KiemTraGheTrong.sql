CREATE OR ALTER PROC usp_KiemTraGheTrong
    @MaChuyenTau nchar(10),
    @MaToa       nchar(5),
    @MaCho       nchar(6),
    @MaGaDi      nchar(5),
    @MaGaDen     nchar(5),
    @ConTrong    bit OUTPUT,
    @ThongBao    nvarchar(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @TrinhTuDiMoi int,
        @TrinhTuDenMoi int;

    -- Lấy trật tự ga của vé đang đặt
    SELECT @TrinhTuDiMoi = TrinhTu
    FROM CHUYEN_GA
    WHERE MaChuyenTau = @MaChuyenTau AND MaGa = @MaGaDi;

    SELECT @TrinhTuDenMoi = TrinhTu
    FROM CHUYEN_GA
    WHERE MaChuyenTau = @MaChuyenTau AND MaGa = @MaGaDen;

    IF @TrinhTuDiMoi IS NULL OR @TrinhTuDenMoi IS NULL
    BEGIN
        SET @ConTrong = 0;
        SET @ThongBao = N'Ga không hợp lệ';
        RETURN -1015;
    END

    -- Kiểm tra tồn tại vé giao nhau
    IF EXISTS (
        SELECT 1
        FROM CHI_TIET_VE CTV
        JOIN DON_DAT_VE DDV ON CTV.MaDon = DDV.MaDon
        JOIN CHUYEN_GA CG_Di  ON CG_Di.MaChuyenTau = DDV.MaChuyenTau AND CG_Di.MaGa = DDV.MaGaDi
        JOIN CHUYEN_GA CG_Den ON CG_Den.MaChuyenTau = DDV.MaChuyenTau AND CG_Den.MaGa = DDV.MaGaDen
        WHERE DDV.MaChuyenTau = @MaChuyenTau
          AND CTV.MaToa = @MaToa
          AND CTV.MaCho = @MaCho
          AND CTV.TrangThai <> N'Đã hủy'
          AND NOT (
                CG_Den.TrinhTu <= @TrinhTuDiMoi
             OR CG_Di.TrinhTu  >= @TrinhTuDenMoi
          )
    )
    BEGIN
        SET @ConTrong = 0;
        SET @ThongBao = N'Chỗ đã bị đặt';
        RETURN 0;
    END

    SET @ConTrong = 1;
    SET @ThongBao = N'Chỗ còn trống';
    RETURN 0;
END
GO
