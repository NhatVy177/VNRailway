-- Trigger cập nhật ThoiGianDuKienDen của CHUYEN_TAU = ThoiGianDen của ga cuối

GO
CREATE OR ALTER TRIGGER TRG_CHUYEN_TAU_EXPECTED_ARRIVAL
ON CHUYEN_GA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Affected AS (
        SELECT DISTINCT MaChuyenTau FROM inserted
        UNION
        SELECT DISTINCT MaChuyenTau FROM deleted
    ),
    LastStop AS (
        SELECT cg.MaChuyenTau, cg.ThoiGianDen,
               ROW_NUMBER() OVER (PARTITION BY cg.MaChuyenTau ORDER BY cg.TrinhTu DESC) AS rn
        FROM CHUYEN_GA cg
        JOIN Affected a ON a.MaChuyenTau = cg.MaChuyenTau
    )
    UPDATE ct
    SET ThoiGianDuKienDen = ls.ThoiGianDen
    FROM CHUYEN_TAU ct
    JOIN Affected a ON a.MaChuyenTau = ct.MaChuyenTau
    JOIN LastStop ls ON ls.MaChuyenTau = ct.MaChuyenTau AND ls.rn = 1;
END
GO
