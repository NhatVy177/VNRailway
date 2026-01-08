CREATE OR ALTER PROC usp_LayChiTietChuyenTau
    @MaChuyenTau nchar(10),
    @MaGaDi      nchar(5),
    @MaGaDen     nchar(5)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CT.MaChuyenTau,
        CT.ThoiGianXuatPhat,
        CT.ThoiGianDuKienDen,

        DT.MaDoanTau,
        DT.TenTau,
        DT.LoaiTau,

        T.MaTuyen,
        T.TenTuyen,

        COUNT(CTV.MaVe) AS SoChoDaDat,

        -- 🔥 GỌI ĐÚNG HÀM – ĐÚNG SỐ THAM SỐ
        dbo.fn_SoChoTrong_ChuyenTau(
            CT.MaChuyenTau,
            @MaGaDi,
            @MaGaDen,
            NULL        -- NULL = tính cho cả GH + GI
        ) AS SoChoConTrong

    FROM CHUYEN_TAU CT
        JOIN DOAN_TAU DT ON CT.MaDoanTau = DT.MaDoanTau
        JOIN TUYEN T     ON CT.MaTuyen  = T.MaTuyen
        LEFT JOIN DON_DAT_VE DDV 
            ON CT.MaChuyenTau = DDV.MaChuyenTau
        LEFT JOIN CHI_TIET_VE CTV 
            ON DDV.MaDon = CTV.MaDon
           AND CTV.TrangThai <> N'Đã hủy'

    WHERE CT.MaChuyenTau = @MaChuyenTau

    GROUP BY
        CT.MaChuyenTau,
        CT.ThoiGianXuatPhat,
        CT.ThoiGianDuKienDen,
        DT.MaDoanTau,
        DT.TenTau,
        DT.LoaiTau,
        T.MaTuyen,
        T.TenTuyen;
END
GO