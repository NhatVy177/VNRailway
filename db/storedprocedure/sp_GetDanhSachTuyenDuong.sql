CREATE OR ALTER PROC sp_GetDanhSachTuyenDuong
AS
BEGIN
    SELECT 
        t.MaTuyen,
        t.TenTuyen,
        -- ✅ Tính QuangDuong từ bảng TUYEN_GA
        ISNULL((
            SELECT SUM(tg.KhoangCach) 
            FROM TUYEN_GA tg 
            WHERE tg.MaTuyen = t.MaTuyen
        ), 0) AS QuangDuong
    FROM TUYEN t
    ORDER BY t.TenTuyen;
END