CREATE OR ALTER PROC usp_LayGiuongTrongToa
    @MaChuyenTau nchar(10),
    @MaToa       nchar(5),
    @MaGaDi      nchar(5),
    @MaGaDen     nchar(5)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        /* 1. Kiểm tra chuyến tàu tồn tại */
        IF NOT EXISTS (
            SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau
        )
        BEGIN
            RETURN -1009;
        END

        /* 2. Kiểm tra toa tồn tại */
        IF NOT EXISTS (
            SELECT 1 FROM TOA_TAU WHERE MaToa = @MaToa
        )
        BEGIN
            RETURN -1015;
        END

        /* 3. Kiểm tra toa thuộc chuyến tàu */
        IF NOT EXISTS (
            SELECT 1
            FROM CHUYEN_TAU CT
            JOIN TOA_TAU TT ON CT.MaDoanTau = TT.MaDoanTau
            WHERE CT.MaChuyenTau = @MaChuyenTau AND TT.MaToa = @MaToa
        )
        BEGIN
            RETURN -1023;
        END

        /* 4. Kiểm tra toa có giường */
        IF NOT EXISTS (
            SELECT 1 FROM GIUONG WHERE MaToa = @MaToa
        )
        BEGIN
            RETURN -1025; -- Toa không có giường
        END

        /* 5. Lấy danh sách giường với trạng thái theo đoạn tuyến */
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
        SELECT
            GI.MaGiuong AS MaCho,
            GI.SoPhong,
            GI.Tang,
            GI.Phia,
            
            -- ✅ Kiểm tra giường đã bán trong đoạn [@MaGaDi, @MaGaDen)
            CASE 
                WHEN EXISTS (
                    SELECT 1
                    FROM CHI_TIET_VE CTV
                    JOIN DON_DAT_VE DDV ON CTV.MaDon = DDV.MaDon
                    JOIN CTE_TrinhTu T ON 1 = 1
                    JOIN CHUYEN_GA DiVe ON DiVe.MaChuyenTau = DDV.MaChuyenTau
                                        AND DiVe.MaGa = DDV.MaGaDi
                    JOIN CHUYEN_GA DenVe ON DenVe.MaChuyenTau = DDV.MaChuyenTau
                                         AND DenVe.MaGa = DDV.MaGaDen
                    WHERE DDV.MaChuyenTau = @MaChuyenTau
                      AND CTV.MaToa = @MaToa
                      AND CTV.MaCho = GI.MaGiuong
                      AND CTV.TrangThai <> N'Đã hủy'
                      -- Giao đoạn
                      AND DiVe.TrinhTu < T.TrinhTuDen
                      AND T.TrinhTuDi < DenVe.TrinhTu
                ) THEN 0
                ELSE 1
            END AS ConTrong,
            
            -- ★ THÊM CỘT GIÁ VÉ
            dbo.fn_TinhGiaVe(
                @MaChuyenTau,
                @MaToa,
                GI.MaGiuong,
                @MaGaDi,
                @MaGaDen
            ) AS GiaVe
            
        FROM GIUONG GI
        WHERE GI.MaToa = @MaToa
        ORDER BY GI.SoPhong, GI.Tang;

        RETURN 0;
    END TRY
    BEGIN CATCH
        RETURN -9005;
    END CATCH
END;
GO