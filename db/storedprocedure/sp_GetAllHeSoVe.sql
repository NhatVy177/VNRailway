USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_GetAllHeSoVe
-- Lấy danh sách tất cả hệ số vé (theo thời gian)
-- =============================================
CREATE OR ALTER PROC sp_GetAllHeSoVe
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MaHeSo,
        NgayBD,
        NgayKT,
        HeSo,
        GhiChu
    FROM HE_SO_VE
    ORDER BY NgayBD;
    
    RETURN 0;
END
GO
