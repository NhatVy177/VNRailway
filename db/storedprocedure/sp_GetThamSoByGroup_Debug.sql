USE VNRAILWAY
GO

-- Test debug version
CREATE OR ALTER PROC sp_GetThamSoByGroup_Debug
    @NhomThamSo NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Debug: In ra giá trị parameter
    SELECT @NhomThamSo AS [Input Parameter];
    
    -- Debug: In ra mapping
    SELECT 
        MaThamSo,
        CASE 
            WHEN MaThamSo IN ('TS001', 'TS002', 'TS003', 'TS004', 'TS005', 'TS006') THEN N'Mua vé'
            WHEN MaThamSo IN ('TS007', 'TS008') THEN N'Đổi vé'
            WHEN MaThamSo IN ('TS009', 'TS010', 'TS011') THEN N'Giảm giá'
            WHEN MaThamSo IN ('TS012', 'TS013', 'TS014', 'TS015', 'TS016', 'TS017') THEN N'Phân công'
        END AS [Computed Group],
        CASE WHEN CASE 
            WHEN MaThamSo IN ('TS001', 'TS002', 'TS003', 'TS004', 'TS005', 'TS006') THEN N'Mua vé'
            WHEN MaThamSo IN ('TS007', 'TS008') THEN N'Đổi vé'
            WHEN MaThamSo IN ('TS009', 'TS010', 'TS011') THEN N'Giảm giá'
            WHEN MaThamSo IN ('TS012', 'TS013', 'TS014', 'TS015', 'TS016', 'TS017') THEN N'Phân công'
        END = @NhomThamSo THEN 'MATCH' ELSE 'NO MATCH' END AS [Comparison Result]
    FROM THAM_SO
    WHERE MaThamSo LIKE 'TS%';
END
GO
