USE VNRAILWAY
GO

CREATE OR ALTER PROC usp_TaoDonDatVe_Online
    @MaChuyenTau    nchar(10),
    @MaGaDi         nchar(5),
    @MaGaDen        nchar(5),
    @MaKH_NguoiDat  nchar(10),
    @PhuongThucTT   nvarchar(12) = N'Chuyển khoản',
    @DanhSachVe     nvarchar(MAX),
    @MaDonMoi       nchar(10) OUTPUT,
    @ThongBao       nvarchar(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;  -- ⚠️ Không lock
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @PhuongThucTT NOT IN (N'Tiền mặt', N'Chuyển khoản')
        BEGIN
            SET @ThongBao = N'Phương thức thanh toán không hợp lệ';
            ROLLBACK TRANSACTION;
            RETURN -1056;
        END

        IF NOT EXISTS (SELECT 1 FROM KHACH_HANG WHERE MaKH = @MaKH_NguoiDat)
        BEGIN
            SET @ThongBao = N'Người đặt không tồn tại';
            ROLLBACK TRANSACTION;
            RETURN -1011;
        END
        
        IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
        BEGIN
            SET @ThongBao = N'Chuyến tàu không tồn tại';
            ROLLBACK TRANSACTION;
            RETURN -1009;
        END
        
        DECLARE @TrinhTuDi int, @TrinhTuDen int;
        
        SELECT @TrinhTuDi = TrinhTu 
        FROM CHUYEN_GA 
        WHERE MaChuyenTau = @MaChuyenTau AND MaGa = @MaGaDi;
        
        SELECT @TrinhTuDen = TrinhTu 
        FROM CHUYEN_GA 
        WHERE MaChuyenTau = @MaChuyenTau AND MaGa = @MaGaDen;
        
        IF @TrinhTuDi IS NULL OR @TrinhTuDen IS NULL
        BEGIN
            SET @ThongBao = N'Ga đi hoặc ga đến không hợp lệ';
            ROLLBACK TRANSACTION;
            RETURN -1015;
        END
        
        IF @TrinhTuDi >= @TrinhTuDen
        BEGIN
            SET @ThongBao = N'Ga đi phải trước ga đến';
            ROLLBACK TRANSACTION;
            RETURN -1050;
        END
        
        DECLARE @SoDon int;
        SET @SoDon = NEXT VALUE FOR SEQ_MA_DON_DAT_VE;
        SET @MaDonMoi = N'DH' + RIGHT(N'000000' + CAST(@SoDon AS nvarchar), 6);
        
        -- =============================================
        -- ⭐ PARSE JSON VÀ TỰ ĐỘNG TẠO KHÁCH HÀNG TẠM
        -- =============================================
        DECLARE @VeTable TABLE (
            MaToa nchar(5),
            MaCho nchar(6),
            MaThamSo nchar(5),
            HoTen nvarchar(50),
            CMND nchar(12),
            SDT nchar(10),
            NgSinh date,
            DiaChi nvarchar(100),
            MaKH nchar(10)
        );
        
        INSERT INTO @VeTable (MaToa, MaCho, MaThamSo, HoTen, CMND, SDT, NgSinh, DiaChi)
        SELECT 
            JSON_VALUE(value, '$.maToa'),
            JSON_VALUE(value, '$.maCho'),
            JSON_VALUE(value, '$.maThamSo'),
            JSON_VALUE(value, '$.hoTen'),
            JSON_VALUE(value, '$.cmnd'),
            JSON_VALUE(value, '$.sdt'),
            TRY_CAST(JSON_VALUE(value, '$.ngSinh') AS date),
            JSON_VALUE(value, '$.diaChi')
        FROM OPENJSON(@DanhSachVe);
        
        -- Tạo khách hàng tạm
        DECLARE @HoTen nvarchar(50), @CMND nchar(12), @MaKH nchar(10);
        DECLARE @SDT nchar(10), @NgSinh date, @DiaChi nvarchar(100);
        DECLARE @ThongBaoTam nvarchar(200);
        DECLARE @RetCodeTam int;
        
        DECLARE cur_TaoKH CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT HoTen, CMND, SDT, NgSinh, DiaChi FROM @VeTable;
        
        OPEN cur_TaoKH;
        FETCH NEXT FROM cur_TaoKH INTO @HoTen, @CMND, @SDT, @NgSinh, @DiaChi;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC @RetCodeTam = usp_ThemKhachHangTam
                @HoTen = @HoTen,
                @CMND = @CMND,
                @SDT = @SDT,
                @NgSinh = @NgSinh,
                @DiaChi = @DiaChi,
                @MaKH = @MaKH OUTPUT,
                @ThongBao = @ThongBaoTam OUTPUT;
            
            IF @RetCodeTam <> 0
            BEGIN
                CLOSE cur_TaoKH;
                DEALLOCATE cur_TaoKH;
                SET @ThongBao = N'Lỗi tạo khách hàng tạm: ' + @ThongBaoTam;
                ROLLBACK TRANSACTION;
                RETURN @RetCodeTam;
            END
            
            UPDATE @VeTable SET MaKH = @MaKH WHERE CMND = @CMND;
            FETCH NEXT FROM cur_TaoKH INTO @HoTen, @CMND, @SDT, @NgSinh, @DiaChi;
        END
        
        CLOSE cur_TaoKH;
        DEALLOCATE cur_TaoKH;
        
        -- Validate số lượng
        DECLARE @SoLuongVe int;
        SELECT @SoLuongVe = COUNT(*) FROM @VeTable;
        
        IF @SoLuongVe = 0
        BEGIN
            SET @ThongBao = N'Danh sách vé trống';
            ROLLBACK TRANSACTION;
            RETURN -1052;
        END
        
        DECLARE @SoVeToiDa int;
        SELECT @SoVeToiDa = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS001';
        
        IF @SoLuongVe > @SoVeToiDa
        BEGIN
            SET @ThongBao = N'Vượt quá ' + CAST(@SoVeToiDa AS nvarchar(10)) + N' vé/đơn';
            ROLLBACK TRANSACTION;
            RETURN -1053;
        END
        
        -- =============================================
        -- ⚠️ LỖI: KIỂM TRA GHẾ KHÔNG LOCK
        -- =============================================
        DECLARE @MaToa nchar(5), @MaCho nchar(6), @MaThamSo nchar(5);
        DECLARE @ConTrong bit;
        DECLARE @ThongBaoGhe nvarchar(200);
        DECLARE @RetCode int;
        
        DECLARE cur_KiemTraGhe CURSOR LOCAL FAST_FORWARD FOR 
            SELECT DISTINCT MaToa, MaCho FROM @VeTable;
        
        OPEN cur_KiemTraGhe;
        FETCH NEXT FROM cur_KiemTraGhe INTO @MaToa, @MaCho;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- ⚠️ Kiểm tra KHÔNG LOCK
            EXEC @RetCode = usp_KiemTraGheTrong 
                @MaChuyenTau, @MaToa, @MaCho, @MaGaDi, @MaGaDen, 
                @ConTrong OUTPUT, @ThongBaoGhe OUTPUT;
            
            IF @RetCode <> 0 OR @ConTrong = 0
            BEGIN
                CLOSE cur_KiemTraGhe;
                DEALLOCATE cur_KiemTraGhe;
                SET @ThongBao = N'Ghế ' + RTRIM(@MaCho) + N' toa ' + RTRIM(@MaToa) + N' đã đặt';
                ROLLBACK TRANSACTION;
                RETURN -1054;
            END
            
            FETCH NEXT FROM cur_KiemTraGhe INTO @MaToa, @MaCho;
        END
        
        CLOSE cur_KiemTraGhe;
        DEALLOCATE cur_KiemTraGhe;
        
        -- ⚠️ DELAY để tăng khả năng Lost Update
        WAITFOR DELAY '00:00:05';
        
        -- Validate tham số
        DECLARE cur_ValidateThamSo CURSOR LOCAL FAST_FORWARD FOR 
            SELECT MaThamSo FROM @VeTable;
        
        OPEN cur_ValidateThamSo;
        FETCH NEXT FROM cur_ValidateThamSo INTO @MaThamSo;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF dbo.fn_KiemTraDoiTuongHopLe(@MaThamSo) = 0
            BEGIN
                CLOSE cur_ValidateThamSo;
                DEALLOCATE cur_ValidateThamSo;
                SET @ThongBao = N'Mã tham số không hợp lệ: ' + ISNULL(@MaThamSo, 'NULL');
                ROLLBACK TRANSACTION;
                RETURN -1055;
            END
            FETCH NEXT FROM cur_ValidateThamSo INTO @MaThamSo;
        END
        
        CLOSE cur_ValidateThamSo;
        DEALLOCATE cur_ValidateThamSo;
        
        -- Tính tổng tiền
        DECLARE @TongTien decimal(12,2) = 0;
        DECLARE @GiaVe decimal(12,2);
        
        DECLARE cur_TinhTien CURSOR LOCAL FAST_FORWARD FOR 
            SELECT MaToa, MaCho, MaThamSo FROM @VeTable;
        
        OPEN cur_TinhTien;
        FETCH NEXT FROM cur_TinhTien INTO @MaToa, @MaCho, @MaThamSo;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @GiaVe = dbo.fn_TinhGiaVe(@MaChuyenTau, @MaToa, @MaCho, @MaGaDi, @MaGaDen);
            SET @TongTien = @TongTien + dbo.fn_TinhThanhTien(@GiaVe, @MaThamSo);
            FETCH NEXT FROM cur_TinhTien INTO @MaToa, @MaCho, @MaThamSo;
        END
        
        CLOSE cur_TinhTien;
        DEALLOCATE cur_TinhTien;
        
        -- Tạo đơn
        INSERT INTO DON_DAT_VE (
            MaDon, ThoiGianDatve, TongTien, 
            MaChuyenTau, MaGaDi, MaGaDen, 
            MaNVBanVe, MaKH
        )
        VALUES (
            @MaDonMoi, CONVERT(datetime, CONVERT(varchar(19), GETDATE(), 120)), @TongTien,
            @MaChuyenTau, @MaGaDi, @MaGaDen,
            NULL, @MaKH_NguoiDat
        );
        
        IF @@ERROR <> 0
        BEGIN
            SET @ThongBao = N'Lỗi khi tạo đơn đặt vé';
            ROLLBACK TRANSACTION;
            RETURN -9001;
        END
        
        -- Tạo chi tiết vé
        DECLARE @MaVeMoi nchar(12);
        DECLARE @KhuyenMai decimal(12,2);
        DECLARE @ThanhTien decimal(12,2);
        
        DECLARE cur_TaoVe CURSOR LOCAL FAST_FORWARD FOR 
            SELECT MaToa, MaCho, MaThamSo, MaKH FROM @VeTable;
        
        OPEN cur_TaoVe;
        FETCH NEXT FROM cur_TaoVe INTO @MaToa, @MaCho, @MaThamSo, @MaKH;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @SoVe int;
            SET @SoVe = NEXT VALUE FOR SEQ_MA_VE;
            SET @MaVeMoi = N'VEDH' + RIGHT(N'000000' + CAST(@SoVe AS nvarchar), 6);

            SET @GiaVe = dbo.fn_TinhGiaVe(@MaChuyenTau, @MaToa, @MaCho, @MaGaDi, @MaGaDen);
            SET @KhuyenMai = dbo.fn_TinhGiamGiaTheoThamSo(@GiaVe, @MaThamSo);
            SET @ThanhTien = @GiaVe - @KhuyenMai;
            
            INSERT INTO CHI_TIET_VE (
                MaVe, ThoiGianXuatVe, TrangThai, KhuyenMai, PhuPhi, 
                DoiTuong, ThanhTien, PhuongThucTT, 
                MaToa, MaCho, MaDon, MaKH
            )
            VALUES (
                @MaVeMoi, NULL, N'Chưa thanh toán', @KhuyenMai, 0,
                @MaThamSo, @ThanhTien, @PhuongThucTT,
                @MaToa, @MaCho, @MaDonMoi, @MaKH
            );
            
            IF @@ERROR <> 0
            BEGIN
                CLOSE cur_TaoVe;
                DEALLOCATE cur_TaoVe;
                SET @ThongBao = N'Lỗi khi tạo chi tiết vé';
                ROLLBACK TRANSACTION;
                RETURN -9002;
            END
            
            FETCH NEXT FROM cur_TaoVe INTO @MaToa, @MaCho, @MaThamSo, @MaKH;
        END
        
        CLOSE cur_TaoVe;
        DEALLOCATE cur_TaoVe;
        
        COMMIT TRANSACTION;
        
        SET @ThongBao = N'Đặt vé thành công cho ' + CAST(@SoLuongVe AS nvarchar(10)) + N' người';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ThongBao = N'Lỗi: ' + ERROR_MESSAGE();
        RETURN -9999;
    END CATCH
END
GO