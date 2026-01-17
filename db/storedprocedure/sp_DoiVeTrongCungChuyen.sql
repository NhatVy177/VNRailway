USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_DoiVeTrongCungChuyen
-- Đổi chỗ (ghế hoặc giường) trong cùng chuyến tàu
-- =============================================
CREATE OR ALTER PROC sp_DoiVeTrongCungChuyen
    @MaVeCu NVARCHAR(10),
    @MaChoMoi NVARCHAR(10),
    @MaVeMoi NVARCHAR(10) OUTPUT,
    @ThongBao NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @KetQua BIT;
        DECLARE @ThongBaoKiemTra NVARCHAR(255);
        DECLARE @PhiDoiVe DECIMAL(10,2);
        DECLARE @GiaVeCu DECIMAL(10,2);
        DECLARE @GiaVeMoi DECIMAL(10,2);
        DECLARE @MaDonCu NVARCHAR(10);
        DECLARE @MaKH NVARCHAR(10);
        DECLARE @MaChuyenTau NVARCHAR(10);
        DECLARE @LoaiChoCu NVARCHAR(10);
        DECLARE @LoaiChoMoi NVARCHAR(10);
        DECLARE @DoiTuong NVARCHAR(20);
        DECLARE @MaToaMoi NVARCHAR(10);
        DECLARE @MaGaDi NVARCHAR(10);
        DECLARE @MaGaDen NVARCHAR(10);
        DECLARE @PhuongThucTT NVARCHAR(20);
        
        -- Kiểm tra điều kiện đổi vé
        EXEC sp_KiemTraDieuKienDoiVe @MaVeCu, @KetQua OUTPUT, @ThongBaoKiemTra OUTPUT;
        
        IF @KetQua = 0
        BEGIN
            SET @ThongBao = @ThongBaoKiemTra;
            ROLLBACK TRANSACTION;
            RETURN 1;
        END
        
        -- Kiểm tra vị trí mới có tồn tại không (có thể là ghế hoặc giường)
        IF NOT EXISTS (
            SELECT 1 FROM VI_TRI_CHO_TRONG
            WHERE MaChoTrong = @MaChoMoi
        )
        BEGIN
            SET @ThongBao = N'Vị trí mới không tồn tại';
            ROLLBACK TRANSACTION;
            RETURN 2;
        END
        
        -- Lấy thông tin vé cũ
        SELECT
            @MaDonCu = ctv.MaDon,
            @MaKH = ctv.MaKH,
            @GiaVeCu = ctv.ThanhTien,
            @DoiTuong = ctv.DoiTuong,
            @MaChuyenTau = ddv.MaChuyenTau,
            @LoaiChoCu = vtct.LoaiCho,
            @MaGaDi = ddv.MaGaDi,
            @MaGaDen = ddv.MaGaDen,
            @PhuongThucTT = ctv.PhuongThucTT
        FROM CHI_TIET_VE ctv
        JOIN DON_DAT_VE ddv ON ctv.MaDon = ddv.MaDon
        JOIN VI_TRI_CHO_TRONG vtct ON ctv.MaCho = vtct.MaChoTrong
        WHERE ctv.MaVe = @MaVeCu;

        -- Kiểm tra vị trí mới có thuộc cùng chuyến tàu không
        IF NOT EXISTS (
            SELECT 1
            FROM VI_TRI_CHO_TRONG vtct
            JOIN TOA_TAU tt ON vtct.MaToa = tt.MaToa
            JOIN CHUYEN_TAU ct ON tt.MaDoanTau = ct.MaDoanTau
            WHERE vtct.MaChoTrong = @MaChoMoi
            AND ct.MaChuyenTau = @MaChuyenTau
        )
        BEGIN
            SET @ThongBao = N'Vị trí mới không thuộc cùng chuyến tàu';
            ROLLBACK TRANSACTION;
            RETURN 3;
        END

        -- Kiểm tra vị trí mới còn trống (chưa có vé đã thanh toán)
        IF EXISTS (
            SELECT 1 FROM CHI_TIET_VE
            WHERE MaCho = @MaChoMoi
            AND TrangThai = N'Đã thanh toán'
        )
        BEGIN
            SET @ThongBao = N'Vị trí này đã có người đặt';
            ROLLBACK TRANSACTION;
            RETURN 4;
        END

        -- Lấy loại chỗ mới và MaToa mới từ VI_TRI_CHO_TRONG
        SELECT @LoaiChoMoi = vtct.LoaiCho, @MaToaMoi = vtct.MaToa
        FROM VI_TRI_CHO_TRONG vtct
        WHERE vtct.MaChoTrong = @MaChoMoi;

        -- Tính giá vé mới dựa trên vị trí mới
        SELECT @GiaVeMoi = dbo.fn_TinhGiaVe(@MaChuyenTau, @MaToaMoi, @MaChoMoi, @MaGaDi, @MaGaDen);
        
        -- Tính phí đổi vé (5% giá vé cũ theo TS007)
        EXEC sp_TinhPhiDoiVe @MaVeCu, @PhiDoiVe OUTPUT;
        
        -- DEBUG: In ra giá trị để kiểm tra
        PRINT '=== DEBUG sp_DoiVeTrongCungChuyen ==='
        PRINT 'Giá vé cũ: ' + CAST(@GiaVeCu AS NVARCHAR(20))
        PRINT 'Giá vé mới: ' + CAST(@GiaVeMoi AS NVARCHAR(20))
        PRINT 'Phí đổi vé: ' + CAST(@PhiDoiVe AS NVARCHAR(20))
        
        -- Tính thành tiền cần thanh toán:
        -- Công thức: (Giá vé mới - Giá vé cũ) + Phí đổi vé
        -- Nếu kết quả < 0 thì = 0 (không hoàn tiền, không thu âm)
        DECLARE @ThanhTien DECIMAL(10,2);
        DECLARE @ChenhLech DECIMAL(10,2);
        
        SET @ChenhLech = @GiaVeMoi - @GiaVeCu;
        
        PRINT 'Chênh lệch: ' + CAST(@ChenhLech AS NVARCHAR(20))
        
        IF @ChenhLech >= 0
        BEGIN
            -- Vé mới đắt hơn hoặc bằng: trả chênh lệch + phí đổi
            SET @ThanhTien = @ChenhLech + @PhiDoiVe;
            PRINT 'Trường hợp: Vé mới đắt hơn'
        END
        ELSE
        BEGIN
            -- Vé mới rẻ hơn: kiểm tra phí đổi có đủ bù chênh lệch không
            DECLARE @TongCanTra DECIMAL(10,2);
            SET @TongCanTra = @ChenhLech + @PhiDoiVe;
            
            PRINT 'Trường hợp: Vé mới rẻ hơn'
            PRINT 'Tổng cần trả (trước kiểm tra): ' + CAST(@TongCanTra AS NVARCHAR(20))
            
            IF @TongCanTra < 0
            BEGIN
                SET @ThanhTien = 0; -- Không thu tiền, không hoàn tiền
                PRINT 'Kết quả: Thanh toán = 0'
            END
            ELSE
            BEGIN
                SET @ThanhTien = @TongCanTra; -- Chỉ thu phần còn lại
                PRINT 'Kết quả: Thanh toán = ' + CAST(@ThanhTien AS NVARCHAR(20))
            END
        END
        
        PRINT 'Thành tiền cuối cùng: ' + CAST(@ThanhTien AS NVARCHAR(20))
        PRINT '=== END DEBUG ==='
        
        -- Cập nhật trạng thái vé cũ thành "Đã hủy"
        UPDATE CHI_TIET_VE
        SET TrangThai = N'Đã hủy'
        WHERE MaVe = @MaVeCu;
        
        -- Cập nhật vị trí chỗ cũ thành trống (không cần update GHE)
        
        -- Tạo mã vé mới (với retry nếu trùng)
        DECLARE @Retry INT = 0;
        WHILE @Retry < 10
        BEGIN
            SET @MaVeMoi = dbo.fn_TaoMaVe();
            
            -- Kiểm tra mã vé đã tồn tại chưa
            IF NOT EXISTS (SELECT 1 FROM CHI_TIET_VE WHERE MaVe = @MaVeMoi)
                BREAK;
                
            SET @Retry = @Retry + 1;
            WAITFOR DELAY '00:00:00.01'; -- Đợi 10ms trước khi thử lại
        END
        
        -- Nếu sau 10 lần vẫn trùng, báo lỗi
        IF @Retry >= 10
        BEGIN
            SET @ThongBao = N'Không thể tạo mã vé mới sau 10 lần thử';
            ROLLBACK TRANSACTION;
            RETURN 5;
        END

        -- Tạo vé mới với vị trí mới
        INSERT INTO CHI_TIET_VE (MaVe, ThoiGianXuatVe, TrangThai, KhuyenMai, PhuPhi, DoiTuong, ThanhTien, PhuongThucTT, MaToa, MaCho, MaDon, MaKH)
        VALUES (@MaVeMoi, GETDATE(), N'Đã thanh toán', 0, 0, @DoiTuong, @ThanhTien, @PhuongThucTT, @MaToaMoi, @MaChoMoi, @MaDonCu, @MaKH);
        
        SET @ThongBao = N'Đổi vé thành công. Mã vé mới: ' + @MaVeMoi 
                      + N'. Phí đổi vé: ' + CAST(@PhiDoiVe AS NVARCHAR(20))
                      + N'. Thành tiền: ' + CAST(@ThanhTien AS NVARCHAR(20));
        
        COMMIT TRANSACTION;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @ThongBao = N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH
END
GO