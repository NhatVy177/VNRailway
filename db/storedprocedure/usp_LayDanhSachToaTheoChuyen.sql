CREATE OR ALTER PROC usp_LayDanhSachToaTheoChuyen
    @MaChuyenTau nchar(10),
    @MaGaDi      nchar(5),
    @MaGaDen     nchar(5)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TT.MaToa,
        TT.STT,
        TT.LoaiToa,
        CASE TT.LoaiToa
            WHEN 'GH'  THEN N'Toa ghế'
            WHEN 'GI4' THEN N'Toa giường 4 tầng'
            WHEN 'GI6' THEN N'Toa giường 6 tầng'
        END AS TenLoaiToa,
        
        -- ✅ GỌI HÀM VỚI 4 THAM SỐ
        dbo.fn_TinhChoTrong_TheoToa(
            @MaChuyenTau, 
            TT.MaToa,
            @MaGaDi,
            @MaGaDen
        ) AS SoChoTrong
        
    FROM CHUYEN_TAU CT
    JOIN TOA_TAU TT ON CT.MaDoanTau = TT.MaDoanTau
    WHERE CT.MaChuyenTau = @MaChuyenTau
    ORDER BY TT.STT;
END;
GO