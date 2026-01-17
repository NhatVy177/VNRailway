USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_GetGiaVeCoban
-- Lấy danh sách giá vé cơ bản theo loại tàu, loại chỗ, tầng
-- =============================================
CREATE OR ALTER PROC sp_GetGiaVeCoban
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MaThamSo,
        CASE 
            WHEN MaThamSo IN ('GV001', 'GV002', 'GV003', 'GV004', 'GV005', 'GV006') THEN N'Hạng sang'
            WHEN MaThamSo IN ('GV007', 'GV008', 'GV009', 'GV010', 'GV011', 'GV012') THEN N'Hạng thường'
        END AS LoaiTau,
        CASE 
            WHEN MaThamSo IN ('GV001', 'GV007') THEN N'Ghế'
            WHEN MaThamSo IN ('GV002', 'GV003', 'GV008', 'GV009') THEN N'Giường phòng 4'
            WHEN MaThamSo IN ('GV004', 'GV005', 'GV006', 'GV010', 'GV011', 'GV012') THEN N'Giường phòng 6'
        END AS LoaiCho,
        CASE 
            WHEN MaThamSo IN ('GV001', 'GV007') THEN 0 -- Ghế không có tầng
            WHEN MaThamSo IN ('GV002', 'GV004', 'GV008', 'GV010') THEN 1 -- Tầng 1
            WHEN MaThamSo IN ('GV003', 'GV005', 'GV009', 'GV011') THEN 2 -- Tầng 2
            WHEN MaThamSo IN ('GV006', 'GV012') THEN 3 -- Tầng 3
        END AS Tang,
        GiaTriThamSo AS GiaCoban
    FROM THAM_SO
    WHERE MaThamSo LIKE 'GV%'
    ORDER BY MaThamSo;
    
    RETURN 0;
END
GO
