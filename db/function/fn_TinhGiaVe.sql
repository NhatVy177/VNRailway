CREATE OR ALTER FUNCTION dbo.fn_TinhGiaVe
(
    @MaChuyenTau nchar(10),
    @MaToa       nchar(5),
    @MaCho       nchar(6),
    @MaGaDi      nchar(5),
    @MaGaDen     nchar(5)
)
RETURNS decimal(12,2)
AS
BEGIN
    DECLARE
        @KhoangCach decimal(6,2),
        @LoaiTau nchar(1),
        @LoaiCho nchar(2),
        @LoaiToa nchar(3),
        @Tang int,
        @GiaKm decimal(12,2),
        @HeSoThoiGian decimal(4,2) = 1,
        @GiaVe decimal(12,2);

    /* 1️⃣ TÍNH KHOẢNG CÁCH */
    SELECT @KhoangCach = SUM(TG.KhoangCach)
    FROM CHUYEN_TAU CT
    JOIN TUYEN_GA TG ON TG.MaTuyen = CT.MaTuyen
    WHERE CT.MaChuyenTau = @MaChuyenTau
      AND TG.TrinhTu >
          (SELECT TrinhTu FROM TUYEN_GA WHERE MaTuyen = CT.MaTuyen AND MaGa = @MaGaDi)
      AND TG.TrinhTu <=
          (SELECT TrinhTu FROM TUYEN_GA WHERE MaTuyen = CT.MaTuyen AND MaGa = @MaGaDen);

    /* 2️⃣ LẤY LOẠI TÀU */
    SELECT @LoaiTau = DT.LoaiTau
    FROM CHUYEN_TAU CT
    JOIN DOAN_TAU DT ON CT.MaDoanTau = DT.MaDoanTau
    WHERE CT.MaChuyenTau = @MaChuyenTau;

    /* 3️⃣ LẤY LOẠI CHỖ */
    SELECT @LoaiCho = LoaiCho
    FROM VI_TRI_CHO_TRONG
    WHERE MaChoTrong = @MaCho AND MaToa = @MaToa;

    /* 4️⃣ LẤY LOẠI TOA */
    SELECT @LoaiToa = LoaiToa
    FROM TOA_TAU
    WHERE MaToa = @MaToa;

    /* 5️⃣ LẤY TẦNG (NẾU LÀ GIƯỜNG) */
    IF @LoaiCho = 'GI'
    BEGIN
        SELECT @Tang = CAST(REPLACE(Tang, N'Tầng ', '') AS int)
        FROM GIUONG
        WHERE MaGiuong = @MaCho AND MaToa = @MaToa;
    END

    /* 6️⃣ XÁC ĐỊNH GIÁ / KM */
    SELECT @GiaKm = GiaTriThamSo
    FROM THAM_SO
    WHERE MaThamSo =
        CASE
            -- GHẾ
            WHEN @LoaiCho = 'GH' AND @LoaiTau = 'S' THEN 'GV001'
            WHEN @LoaiCho = 'GH' AND @LoaiTau = 'T' THEN 'GV007'

            -- GIƯỜNG 4
            WHEN @LoaiCho = 'GI' AND @LoaiToa = 'GI4' AND @LoaiTau = 'S' AND @Tang = 1 THEN 'GV002'
            WHEN @LoaiCho = 'GI' AND @LoaiToa = 'GI4' AND @LoaiTau = 'S' AND @Tang = 2 THEN 'GV003'
            WHEN @LoaiCho = 'GI' AND @LoaiToa = 'GI4' AND @LoaiTau = 'T' AND @Tang = 1 THEN 'GV008'
            WHEN @LoaiCho = 'GI' AND @LoaiToa = 'GI4' AND @LoaiTau = 'T' AND @Tang = 2 THEN 'GV009'

            -- GIƯỜNG 6
            WHEN @LoaiCho = 'GI' AND @LoaiToa = 'GI6' AND @LoaiTau = 'S' AND @Tang = 1 THEN 'GV004'
            WHEN @LoaiCho = 'GI' AND @LoaiToa = 'GI6' AND @LoaiTau = 'S' AND @Tang = 2 THEN 'GV005'
            WHEN @LoaiCho = 'GI' AND @LoaiToa = 'GI6' AND @LoaiTau = 'S' AND @Tang = 3 THEN 'GV006'
            WHEN @LoaiCho = 'GI' AND @LoaiToa = 'GI6' AND @LoaiTau = 'T' AND @Tang = 1 THEN 'GV010'
            WHEN @LoaiCho = 'GI' AND @LoaiToa = 'GI6' AND @LoaiTau = 'T' AND @Tang = 2 THEN 'GV011'
            WHEN @LoaiCho = 'GI' AND @LoaiToa = 'GI6' AND @LoaiTau = 'T' AND @Tang = 3 THEN 'GV012'
        END;

    /* 7️⃣ HỆ SỐ THỜI GIAN */
    SELECT @HeSoThoiGian = MAX(HeSo)
    FROM HE_SO_VE
    WHERE GETDATE() BETWEEN NgayBD AND NgayKT;

    IF @HeSoThoiGian IS NULL SET @HeSoThoiGian = 1;

    /* 8️⃣ GIÁ CUỐI */
    SET @GiaVe = @KhoangCach * @GiaKm * @HeSoThoiGian;

    RETURN ROUND(@GiaVe, 0);
END
GO