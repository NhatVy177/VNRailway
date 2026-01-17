USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_TinhPhiDoiVe
-- Tính phí đổi vé theo tham số TS007
-- =============================================
CREATE OR ALTER PROC sp_TinhPhiDoiVe
    @MaVe NVARCHAR(10),
    @PhiDoiVe DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @GiaVeCu DECIMAL(10,2);
    DECLARE @TyLePhiDoiVe DECIMAL(5,4);
    
    -- Lấy tỷ lệ phí đổi vé từ tham số (TS007: 5%)
    SELECT @TyLePhiDoiVe = GiaTriThamSo / 100.0
    FROM THAM_SO
    WHERE MaThamSo = 'TS007';
    
    -- Lấy giá vé cũ
    SELECT @GiaVeCu = ThanhTien
    FROM CHI_TIET_VE
    WHERE MaVe = @MaVe;
    
    -- Tính phí đổi vé = giá vé cũ * tỷ lệ phí
    SET @PhiDoiVe = @GiaVeCu * @TyLePhiDoiVe;
    
    RETURN 0;
END
GO
