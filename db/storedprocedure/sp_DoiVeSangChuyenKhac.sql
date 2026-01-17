USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_DoiVeSangChuyenKhac
-- Đổi vé sang chuyến tàu khác
-- =============================================
CREATE OR ALTER PROC sp_DoiVeSangChuyenKhac
    @MaVeCu NVARCHAR(10),
    @MaChuyenTauMoi NVARCHAR(10),
    @MaGheMoi NVARCHAR(10),
    @MaDonMoi NVARCHAR(10) OUTPUT,
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
        DECLARE @MaKH NVARCHAR(10);
        DECLARE @LoaiGheMoi NVARCHAR(10);
        DECLARE @DoiTuong NVARCHAR(20);
        DECLARE @MaGheCu NVARCHAR(10);
        
        -- Kiểm tra điều kiện đổi vé
        EXEC sp_KiemTraDieuKienDoiVe @MaVeCu, @KetQua OUTPUT, @ThongBaoKiemTra OUTPUT;
        
        IF @KetQua = 0
        BEGIN
            SET @ThongBao = @ThongBaoKiemTra;
            ROLLBACK TRANSACTION;
            RETURN 1;
        END
        
        -- Kiểm tra chuyến tàu mới tồn tại
        IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTauMoi)
        BEGIN
            SET @ThongBao = N'Chuyến tàu mới không tồn tại';
            ROLLBACK TRANSACTION;
            RETURN 2;
        END
        
        -- Kiểm tra ghế mới có tồn tại không
        IF NOT EXISTS (
            SELECT 1 FROM GHE 
            WHERE MaGhe = @MaGheMoi
        )
        BEGIN
            SET @ThongBao = N'Ghế mới không tồn tại';
            ROLLBACK TRANSACTION;
            RETURN 3;
        END
        
        -- Lấy thông tin vé cũ
        DECLARE @MaChoCu NVARCHAR(10);
        SELECT 
            @MaKH = ctv.MaKH,
            @GiaVeCu = ctv.ThanhTien,
            @DoiTuong = ctv.DoiTuong,
            @MaChoCu = ctv.MaCho
        FROM CHI_TIET_VE ctv
        WHERE ctv.MaVe = @MaVeCu;
        
        -- Lấy loại ghế mới
        SELECT @LoaiGheMoi = vtct.LoaiCho 
        FROM VI_TRI_CHO_TRONG vtct
        WHERE vtct.MaChoTrong = @MaGheMoi;
        
        -- Tính giá vé mới cho chuyến tàu mới
        EXEC fn_TinhGiaVe @MaChuyenTauMoi, @LoaiGheMoi, @DoiTuong, @GiaVeMoi OUTPUT;
        
        -- Tính phí đổi vé
        EXEC sp_TinhPhiDoiVe @MaVeCu, @PhiDoiVe OUTPUT;
        
        -- Tính thành tiền cần thanh toán:
        -- Công thức: (Giá vé mới - Giá vé cũ) + Phí đổi vé
        -- Nếu kết quả < 0 thì = 0 (không hoàn tiền, không thu âm)
        DECLARE @ThanhTien DECIMAL(10,2);
        DECLARE @ChenhLech DECIMAL(10,2);
        
        SET @ChenhLech = @GiaVeMoi - @GiaVeCu;
        
        IF @ChenhLech >= 0
        BEGIN
            -- Vé mới đắt hơn hoặc bằng: trả chênh lệch + phí đổi
            SET @ThanhTien = @ChenhLech + @PhiDoiVe;
        END
        ELSE
        BEGIN
            -- Vé mới rẻ hơn: kiểm tra phí đổi có đủ bù chênh lệch không
            DECLARE @TongCanTra DECIMAL(10,2);
            SET @TongCanTra = @ChenhLech + @PhiDoiVe;
            
            IF @TongCanTra < 0
                SET @ThanhTien = 0; -- Không thu tiền, không hoàn tiền
            ELSE
                SET @ThanhTien = @TongCanTra; -- Chỉ thu phần còn lại
        END
        
        -- Cập nhật trạng thái vé cũ thành "Đã hủy"
        UPDATE CHI_TIET_VE
        SET TrangThai = N'Đã hủy'
        WHERE MaVe = @MaVeCu;
        
        -- Vị trí chỗ cũ tự động trống khi vé bị hủy
        
        -- Tạo mã đơn đặt vé mới
        EXEC @MaDonMoi = dbo.fn_TaoMaDonDatVe;
        
        -- Lấy ga đi và ga đến từ đơn cũ
        DECLARE @MaGaDi NVARCHAR(10), @MaGaDen NVARCHAR(10);
        SELECT @MaGaDi = MaGaDi, @MaGaDen = MaGaDen
        FROM DON_DAT_VE
        WHERE MaDon = (SELECT MaDon FROM CHI_TIET_VE WHERE MaVe = @MaVeCu);
        
        -- Tạo đơn đặt vé mới
        INSERT INTO DON_DAT_VE (MaDon, ThoiGianDatve, TongTien, MaChuyenTau, MaGaDi, MaGaDen, MaNVBanVe, MaKH)
        VALUES (@MaDonMoi, GETDATE(), @ThanhTien, @MaChuyenTauMoi, @MaGaDi, @MaGaDen, NULL, @MaKH);
        
        -- Tạo mã vé mới
        EXEC @MaVeMoi = dbo.fn_TaoMaVe;
        
        -- Lấy MaCho mới (chính là @MaGheMoi)
        DECLARE @MaChoMoi NVARCHAR(10);
        SET @MaChoMoi = @MaGheMoi;
        
        -- Tạo vé mới với vị trí mới
        INSERT INTO CHI_TIET_VE (MaVe, ThoiGianXuatVe, TrangThai, KhuyenMai, PhuPhi, DoiTuong, ThanhTien, PhuongThucTT, MaToa, MaCho, MaDon, MaKH)
        SELECT @MaVeMoi, GETDATE(), N'Đã thanh toán', 0, 0, @DoiTuong, @ThanhTien, N'Tiền mặt',
               vtct.MaToa, @MaChoMoi, @MaDonMoi, @MaKH
        FROM VI_TRI_CHO_TRONG vtct
        WHERE vtct.MaChoTrong = @MaChoMoi;
        
        SET @ThongBao = N'Đổi vé thành công. Đơn mới: ' + @MaDonMoi 
                      + N', Vé mới: ' + @MaVeMoi 
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
