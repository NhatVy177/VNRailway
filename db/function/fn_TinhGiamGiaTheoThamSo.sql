USE VNRAILWAY
GO
CREATE OR ALTER FUNCTION dbo.fn_TinhGiamGiaTheoThamSo
(
    @GiaGoc decimal(12,2),
    @MaThamSo nchar(5)  -- TS009, TS010, TS011
)
RETURNS decimal(12,2)
AS
BEGIN
    DECLARE @TyLeGiam decimal(4,2) = 0;
    DECLARE @SoTienGiam decimal(12,2);
    
    -- Đọc tỷ lệ giảm từ bảng THAM_SO
    IF @MaThamSo IS NOT NULL
    BEGIN
        SELECT @TyLeGiam = GiaTriThamSo
        FROM THAM_SO
        WHERE MaThamSo = @MaThamSo;
    END
    
    -- Tính số tiền giảm (làm tròn)
    SET @SoTienGiam = ROUND(@GiaGoc * ISNULL(@TyLeGiam, 0), 0);
    
    RETURN @SoTienGiam;
END
GO