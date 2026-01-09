use VNRAILWAY
-- =============================================
-- Function: fn_TaoMaDonDatVe
-- Mô tả: Tạo mã đơn đặt vé tự động
-- Format: DH + 7 chữ số (DH0000001, DH0000002...)
-- Return: nchar(10)
-- =============================================
GO
CREATE OR ALTER FUNCTION fn_TaoMaDonDatVe ()
RETURNS nchar(8)
AS
BEGIN
    DECLARE @NextNumber INT;
    DECLARE @MaDon nchar(8);

    SELECT @NextNumber =
        ISNULL(
            MAX(CAST(SUBSTRING(MaDon, 3, 6) AS INT)),
            0
        ) + 1
    FROM DON_DAT_VE
    WHERE MaDon LIKE 'DH%';

    SET @MaDon = 'DH' + RIGHT('000000' + CAST(@NextNumber AS varchar(6)), 6);

    RETURN @MaDon;
END;
GO
