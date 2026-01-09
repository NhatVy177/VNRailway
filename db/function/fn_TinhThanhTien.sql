-- =============================================
-- Function: fn_TinhThanhTien
-- Mô tả: Tính thành tiền sau khi trừ giảm giá
-- Input: @GiaGoc, @DoiTuong
-- Return: Thành tiền (decimal)
-- =============================================
USE VNRAILWAY
GO
CREATE OR ALTER FUNCTION dbo.fn_TinhThanhTien
(
    @GiaGoc decimal(12,2),
    @MaThamSo nchar(5)  -- TS009, TS010, TS011, NULL
)
RETURNS decimal(12,2)
AS
BEGIN
    DECLARE @SoTienGiam decimal(12,2);
    DECLARE @ThanhTien decimal(12,2);
    
    -- Tính số tiền giảm
    SET @SoTienGiam = dbo.fn_TinhGiamGiaTheoThamSo(@GiaGoc, @MaThamSo);
    
    -- Thành tiền = Giá gốc - Giảm giá
    SET @ThanhTien = @GiaGoc - @SoTienGiam;
    
    RETURN @ThanhTien;
END
GO