USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_GetDanhSachLoaiCho
-- Lấy danh sách loại chỗ ngồi (cho dropdown filter)
-- =============================================
CREATE OR ALTER PROC sp_GetDanhSachLoaiCho
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT
        tt.LoaiToa,
        CASE 
            WHEN tt.LoaiToa = N'Ghế' THEN N'Ghế ngồi'
            ELSE N'Giường nằm'
        END AS TenLoaiCho
    FROM TOA_TAU tt
    ORDER BY tt.LoaiToa;
    
    RETURN 0;
END
GO
