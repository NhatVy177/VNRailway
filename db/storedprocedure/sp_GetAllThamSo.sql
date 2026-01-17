USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_GetAllThamSo
-- Lấy tất cả tham số hệ thống
-- Phân loại theo nhóm: Giá vé, Mua vé, Đổi vé, Giảm giá, Phân công
-- =============================================
CREATE OR ALTER PROC sp_GetAllThamSo
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MaThamSo,
        TenThamSo,
        GiaTriThamSo,
        -- Phân loại nhóm tham số
        CASE 
            WHEN MaThamSo LIKE 'GV%' THEN N'Giá vé'
            WHEN MaThamSo IN ('TS001', 'TS002', 'TS003', 'TS004', 'TS005', 'TS006') THEN N'Mua vé'
            WHEN MaThamSo IN ('TS007', 'TS008') THEN N'Đổi vé'
            WHEN MaThamSo IN ('TS009', 'TS010', 'TS011') THEN N'Giảm giá'
            WHEN MaThamSo IN ('TS012', 'TS013', 'TS014', 'TS015', 'TS016', 'TS017') THEN N'Phân công'
            ELSE N'Khác'
        END AS NhomThamSo,
        -- Đơn vị
        CASE 
            WHEN TenThamSo LIKE N'%(%vé)%' THEN N'vé'
            WHEN TenThamSo LIKE N'%(ngày)%' THEN N'ngày'
            WHEN TenThamSo LIKE N'%(phút)%' THEN N'phút'
            WHEN TenThamSo LIKE N'%(giờ)%' THEN N'giờ'
            WHEN TenThamSo LIKE N'%(km)%' THEN N'km'
            WHEN TenThamSo LIKE N'%(%)%' THEN N'%'
            WHEN MaThamSo LIKE 'GV%' THEN N'đồng/km'
            ELSE N''
        END AS DonVi
    FROM THAM_SO
    ORDER BY MaThamSo;
    
    RETURN 0;
END
GO
