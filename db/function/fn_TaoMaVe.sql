CREATE OR ALTER FUNCTION fn_TaoMaVe ()
RETURNS nchar(10)
AS
BEGIN
    DECLARE @NextNumber INT;
    DECLARE @MaVe nchar(10);

    SELECT @NextNumber =
        ISNULL(
            MAX(CAST(SUBSTRING(MaVe, 5, 6) AS INT)),
            0
        ) + 1
    FROM CHI_TIET_VE
    WHERE MaVe LIKE 'VEDH%';

    SET @MaVe = 'VEDH' + RIGHT('000000' + CAST(@NextNumber AS varchar(6)), 6);

    RETURN @MaVe;
END;
GO
