USE VNRAILWAY
GO

/* =============================================
   PROCEDURE: sp_ThongKeDoanhThuTheoThang_ERR
   Mô tả: Thống kê doanh thu theo tháng với READ COMMITTED
          Gây ra Unrepeatable Read vì không giữ S lock
   ============================================= */
CREATE OR ALTER PROCEDURE sp_ThongKeDoanhThuTheoThang_ERR
    @ThangBatDau INT,
    @NamBatDau INT,
    @ThangKetThuc INT,
    @NamKetThuc INT
AS
BEGIN
    SET NOCOUNT ON;
    
    --  READ COMMITTED: Giải phóng S lock ngay sau khi đọc
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- B1: Khai báo khoảng thời gian
        DECLARE @NgayBatDau DATE = DATEFROMPARTS(@NamBatDau, @ThangBatDau, 1);
        DECLARE @NgayKetThuc DATE = EOMONTH(DATEFROMPARTS(@NamKetThuc, @ThangKetThuc, 1));

        -- B2: Đọc lần 1 - Thống kê vé
      
        SELECT
            YEAR(ct.ThoiGianXuatPhat) AS Nam,
            MONTH(ct.ThoiGianXuatPhat) AS Thang,
            COUNT(ctv.MaVe) AS SoVe,
            ISNULL(SUM(ctv.ThanhTien), 0) AS TongDoanhThu
        FROM CHI_TIET_VE ctv
        JOIN DON_DAT_VE ddv ON ctv.MaDon = ddv.MaDon
        JOIN CHUYEN_TAU ct ON ddv.MaChuyenTau = ct.MaChuyenTau
        WHERE 
            ctv.TrangThai = N'Đã thanh toán'
            AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
            AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
        GROUP BY YEAR(ct.ThoiGianXuatPhat), MONTH(ct.ThoiGianXuatPhat)
        ORDER BY Nam, Thang;
        
        -- READ COMMITTED: S lock đã được giải phóng sau SELECT

        -- Chờ 10 giây để T2 có cơ hội UPDATE
        PRINT N'>>> Đang chờ 10 giây... (T2 có thể UPDATE trong lúc này)';
        WAITFOR DELAY '00:00:10';

        -- B3: Đọc lần 2 - Thống kê lại
        PRINT N'>>> LẦN ĐỌC 2:';
        SELECT
            YEAR(ct.ThoiGianXuatPhat) AS Nam,
            MONTH(ct.ThoiGianXuatPhat) AS Thang,
            COUNT(ctv.MaVe) AS SoVe,
            ISNULL(SUM(ctv.ThanhTien), 0) AS TongDoanhThu
        FROM CHI_TIET_VE ctv
        JOIN DON_DAT_VE ddv ON ctv.MaDon = ddv.MaDon
        JOIN CHUYEN_TAU ct ON ddv.MaChuyenTau = ct.MaChuyenTau
        WHERE 
            ctv.TrangThai = N'Đã thanh toán'
            AND CAST(ct.ThoiGianXuatPhat AS DATE) >= @NgayBatDau
            AND CAST(ct.ThoiGianXuatPhat AS DATE) <= @NgayKetThuc
        GROUP BY YEAR(ct.ThoiGianXuatPhat), MONTH(ct.ThoiGianXuatPhat)
        ORDER BY Nam, Thang;

        -- ⚠️ KẾT QUẢ: Lần đọc 2 KHÁC lần đọc 1 (Unrepeatable Read)

        COMMIT TRANSACTION;
        PRINT N'>>> UNREPEATABLE READ: Kết quả 2 lần đọc KHÁC NHAU!';
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH
END
GO

-- Test thực thi
PRINT N'=== T1: Bắt đầu thống kê doanh thu (READ COMMITTED) ===';
EXEC sp_ThongKeDoanhThuTheoThang_ERR 
    @ThangBatDau = 5,
    @NamBatDau = 2024,
    @ThangKetThuc = 7,
    @NamKetThuc = 2024;