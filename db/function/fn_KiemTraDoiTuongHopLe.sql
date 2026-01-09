USE VNRAILWAY
GO
CREATE OR ALTER FUNCTION dbo.fn_KiemTraDoiTuongHopLe
(
    @MaThamSo nchar(5)
)
RETURNS bit
AS
BEGIN
    DECLARE @HopLe bit = 0;
    
    -- NULL: Không giảm giá - hợp lệ
    IF @MaThamSo IS NULL
    BEGIN
        SET @HopLe = 1;
    END
    ELSE
    BEGIN
        -- Kiểm tra mã tham số có tồn tại trong bảng THAM_SO không
        IF EXISTS (SELECT 1 FROM THAM_SO WHERE MaThamSo = @MaThamSo)
        BEGIN
            SET @HopLe = 1;
        END
    END
    
    RETURN @HopLe;
END
GO