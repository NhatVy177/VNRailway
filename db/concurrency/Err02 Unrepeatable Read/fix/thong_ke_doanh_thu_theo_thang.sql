USE VNRAILWAY
GO

/* =============================================
   PROCEDURE: sp_ThongKeDoanhThuTheoThang_FIX
   Mô tả: Thống kê doanh thu theo tháng với REPEATABLE READ
          Giữ S lock cho đến COMMIT để tránh Unrepeatable Read
   ============================================= */
CREATE OR ALTER PROCEDURE sp_ThongKeDoanhThuTheoThang_FIX
    @ThangBatDau INT,
    @NamBatDau INT,
    @ThangKetThuc INT,
    @NamKetThuc INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- ⭐ FIX: Sử dụng REPEATABLE READ
    -- Giữ S lock cho đến khi COMMIT
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- B1: Khai báo khoảng thời gian
        DECLARE @NgayBatDau DATE = DATEFROMPARTS(@NamBatDau, @ThangBatDau, 1);
        DECLARE @NgayKetThuc DATE = EOMONTH(DATEFROMPARTS(@NamKetThuc, @ThangKetThuc, 1));

        -- B2: Đọc dữ liệu - GIỮ SHARED LOCK
        PRINT N'>>> Đọc thống kê doanh thu...';
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
        
        -- ⭐ S LOCK được giữ cho đến COMMIT
        -- Transaction khác muốn UPDATE sẽ bị CHẶN

        -- Chờ 10 giây để demo
        PRINT N'>>> Đang giữ S lock trong 10 giây... (T2 sẽ bị CHẶN nếu cố UPDATE)';
        WAITFOR DELAY '00:00:10';

        -- B3: Tiếp tục xử lý khác (nếu có)
        PRINT N'>>> Hoàn thành xử lý thống kê';

        COMMIT TRANSACTION;
        
        PRINT N'>>> REPEATABLE READ: Dữ liệu nhất quán, T2 bị BLOCK!';
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
PRINT N'=== T1: Bắt đầu thống kê doanh thu (REPEATABLE READ) ===';
EXEC sp_ThongKeDoanhThuTheoThang_FIX 
    @ThangBatDau = 5,
    @NamBatDau = 2024,
    @ThangKetThuc = 7,
    @NamKetThuc = 2024;