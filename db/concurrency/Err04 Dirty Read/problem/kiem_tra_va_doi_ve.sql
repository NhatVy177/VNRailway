USE VNRAILWAY
GO

CREATE OR ALTER PROCEDURE sp_KiemTraVaDoiVe
    @MaKH nchar(10),
    @MaVeCu nchar(12),
    @MaChuyenTauCanDoi nchar(10)
AS
BEGIN

    DECLARE @ThoiGianXuatPhat datetime
    DECLARE @ThoiGianHienTai datetime = GETDATE()
    DECLARE @KhoangCachPhut int
    DECLARE @ThoiGianDoiVeToiThieu int
    DECLARE @TiLePhiDoiVe decimal(5,2)
    DECLARE @GiaVeCu decimal(12,2)
    DECLARE @ThanhTienMoi decimal(12,2)
    DECLARE @PhiDoiVe decimal(12,2)
    DECLARE @TienHoan decimal(12,2) -- Số tiền hoàn lại

    BEGIN TRY
        BEGIN TRANSACTION
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

        WAITFOR DELAY '00:00:00' -- Đợi cho T1 thực hiện xong và giữ giao tác mở


        -- B1: Kiểm tra mã vé có tồn tại trong hệ thống không
        IF NOT EXISTS (SELECT 1 FROM CHI_TIET_VE WHERE MaVe = @MaVeCu)
        BEGIN
            PRINT N' Không tìm thấy vé trong hệ thống. Vui lòng kiểm tra lại!'
            ROLLBACK
            RETURN
        END
        PRINT N'Mã vé ' + @MaVeCu + N' đã tồn tại trong hệ thống.'

        -- Lấy tham số từ bảng THAM_SO
        SELECT @ThoiGianDoiVeToiThieu = GiaTriThamSo 
        FROM THAM_SO 
        WHERE MaThamSo = 'TS008' -- 240 phút (4 giờ)

        SELECT @TiLePhiDoiVe = GiaTriThamSo / 100 
        FROM THAM_SO 
        WHERE MaThamSo = 'TS007' -- 5%

        PRINT N'Quy định đổi vé: Trước ' + CAST(@ThoiGianDoiVeToiThieu AS nvarchar(10)) + N' phút'
        PRINT N'Phí đổi vé: ' + CAST(@TiLePhiDoiVe * 100 AS nvarchar(10)) + N'%'

        -- B2: Đọc giờ khởi hành của chuyến tàu cũ (DIRTY READ)
        IF EXISTS (SELECT * FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTauCanDoi)
        BEGIN
            SELECT @ThoiGianXuatPhat = ThoiGianXuatPhat
            FROM CHUYEN_TAU
            WHERE MaChuyenTau = @MaChuyenTauCanDoi

            PRINT N'Tìm thấy chuyến tàu ' + @MaChuyenTauCanDoi
            PRINT N'Thời gian khởi hành: ' + CONVERT(varchar, @ThoiGianXuatPhat, 120)

            -- B3: Kiểm tra điều kiện đổi vé
            SET @KhoangCachPhut = DATEDIFF(MINUTE, @ThoiGianHienTai, @ThoiGianXuatPhat)

            PRINT N'Thời gian hiện tại: ' + CONVERT(varchar, @ThoiGianHienTai, 120)
            PRINT N'Khoảng cách: ' + CAST(@KhoangCachPhut AS nvarchar(10)) + N' phút'

            IF @KhoangCachPhut >= @ThoiGianDoiVeToiThieu
            BEGIN
                PRINT N'✓ Thỏa điều kiện đổi vé (' + CAST(@KhoangCachPhut AS nvarchar(10)) + 
                      N' >= ' + CAST(@ThoiGianDoiVeToiThieu AS nvarchar(10)) + N' phút)'

                -- Lấy giá vé cũ từ vé khách hàng cũ
                SELECT @GiaVeCu = ThanhTien
                FROM CHI_TIET_VE
                WHERE MaVe = @MaVeCu

                -- Tính phí đổi vé
                SET @PhiDoiVe = @GiaVeCu * @TiLePhiDoiVe

                PRINT N'Giá vé cũ: ' + FORMAT(@GiaVeCu, 'N0') + N'đ'
                PRINT N'Phí đổi vé: ' + FORMAT(@PhiDoiVe, 'N0') + N'đ'

                -- Tính số tiền hoàn lại cho khách hàng
                SET @TienHoan = @GiaVeCu - @PhiDoiVe -- Hoàn lại phần còn lại sau khi trừ phí đổi vé
                PRINT N'Hoàn tiền cho khách hàng: ' + FORMAT(@TienHoan, 'N0') + N'đ'

                -- B4: Hủy vé cũ (không tạo vé mới)
                PRINT N'Đang hủy vé cũ...'
                UPDATE CHI_TIET_VE
                SET TrangThai = N'Đã hủy'
                WHERE MaVe = @MaVeCu

                PRINT N'Đổi vé thành công (hủy vé cũ và hoàn tiền cho khách hàng)!'
            END
            ELSE
            BEGIN
                PRINT N'Không thể đổi vé: ' + CAST(@KhoangCachPhut AS nvarchar(10)) + 
                      N' < ' + CAST(@ThoiGianDoiVeToiThieu AS nvarchar(10)) + N' phút'
            END
        END
        ELSE
        BEGIN
            PRINT N'Không tìm thấy chuyến tàu ' + @MaChuyenTauCanDoi
        END

        COMMIT
        PRINT N'COMMIT - Hoàn tất giao dịch'
        PRINT N'========================================='
    END TRY
    BEGIN CATCH
        PRINT N'Lỗi trong quá trình giao dịch. Rollback tất cả thay đổi!'
        ROLLBACK
        PRINT N'========================================='
    END CATCH
END
GO