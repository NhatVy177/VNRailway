-- Tính thời gian đi và thời gian đến của từng chặng
-- Trường hợp ga đầu và ga đích thì thời gian bằng nhau
-- Các ga còn lại, thời gian đi = thời gian đến + 5 phút 

CREATE OR ALTER TRIGGER TRG_CHUYEN_GA_CALC_TIME
ON dbo.CHUYEN_GA
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    ;WITH AffectedTrips AS (
        SELECT DISTINCT MaChuyenTau FROM inserted
    ),
    TripInfo AS (
        SELECT ct.MaChuyenTau, ct.MaTuyen, ct.ThoiGianXuatPhat
        FROM dbo.CHUYEN_TAU ct
        JOIN AffectedTrips a ON a.MaChuyenTau = ct.MaChuyenTau
    ),
    MaxTT AS (
        SELECT cg.MaChuyenTau, MAX(cg.TrinhTu) AS MaxTrinhTu
        FROM dbo.CHUYEN_GA cg
        JOIN AffectedTrips a ON a.MaChuyenTau = cg.MaChuyenTau
        GROUP BY cg.MaChuyenTau
    ),
    Stops AS (
        -- TG của trinhTu k là chặng k -> k+1
        SELECT
            cg.MaChuyenTau,
            cg.TrinhTu,
            mt.MaxTrinhTu,
            ti.ThoiGianXuatPhat,
            tg.TGDiChuyenGiuaCacGa AS TravelToNext
        FROM dbo.CHUYEN_GA cg
        JOIN TripInfo ti ON ti.MaChuyenTau = cg.MaChuyenTau
        JOIN MaxTT mt ON mt.MaChuyenTau = cg.MaChuyenTau
        JOIN dbo.TUYEN_GA tg
          ON tg.MaTuyen = ti.MaTuyen
         AND tg.TrinhTu = cg.TrinhTu
    ),
    R AS (
        -- Ga 1: Den = Di = ThoiGianXuatPhat (datetime thật, có ngày)
        SELECT
            s.MaChuyenTau, s.TrinhTu, s.MaxTrinhTu,
            CAST(s.ThoiGianXuatPhat AS datetime) AS DenDT,
            CAST(s.ThoiGianXuatPhat AS datetime) AS DiDT,
            s.TravelToNext
        FROM Stops s
        WHERE s.TrinhTu = 1

        UNION ALL

        -- Ga k>1: Den(k)=Di(k-1)+TG(k-1)  (TG lấy từ row trước: r.TravelToNext)
        SELECT
            s.MaChuyenTau, s.TrinhTu, s.MaxTrinhTu,
            DATEADD(SECOND,
                DATEDIFF(SECOND, CAST('00:00:00' AS time), r.TravelToNext),
                r.DiDT
            ) AS DenDT,
            CASE
                WHEN s.TrinhTu = s.MaxTrinhTu
                    THEN DATEADD(SECOND,
                        DATEDIFF(SECOND, CAST('00:00:00' AS time), r.TravelToNext),
                        r.DiDT
                    )
                ELSE DATEADD(MINUTE, 5,
                    DATEADD(SECOND,
                        DATEDIFF(SECOND, CAST('00:00:00' AS time), r.TravelToNext),
                        r.DiDT
                    )
                )
            END AS DiDT,
            s.TravelToNext
        FROM R
        JOIN Stops s
          ON s.MaChuyenTau = r.MaChuyenTau
         AND s.TrinhTu     = r.TrinhTu + 1
    )
    UPDATE cg
    SET
        ThoiGianDen = r.DenDT,
        ThoiGianDi  = r.DiDT
    FROM dbo.CHUYEN_GA cg
    JOIN R
      ON R.MaChuyenTau = cg.MaChuyenTau
     AND R.TrinhTu     = cg.TrinhTu
    OPTION (MAXRECURSION 32767);
END
GO

-- Update
UPDATE CHUYEN_GA
SET TrinhTu = TrinhTu
-- Test
SELECT * FROM CHUYEN_GA
WHERE MaChuyenTau = 'VNW051D768'
ORDER BY TrinhTu 