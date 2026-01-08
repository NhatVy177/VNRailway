CREATE OR ALTER PROC usp_TinhGiaVe
    @MaChuyenTau nchar(10),
    @MaToa nchar(5),
    @MaCho nchar(6),
    @MaGaDi nchar(5),
    @MaGaDen nchar(5)
AS
BEGIN
    SELECT dbo.fn_TinhGiaVe(
        @MaChuyenTau,
        @MaToa,
        @MaCho,
        @MaGaDi,
        @MaGaDen
    ) AS GiaVe;
END
GO