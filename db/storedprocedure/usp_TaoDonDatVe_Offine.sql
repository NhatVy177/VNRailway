CREATE OR ALTER PROC usp_TaoDonDatVe_Offline
    @MaChuyenTau    NCHAR(10),
    @MaGaDi         NCHAR(5),
    @MaGaDen        NCHAR(5),
    @MaNVBanVe      NCHAR(10),          -- Mã nhân viên bán vé
    @PhuongThucTT   NVARCHAR(12) = N'Tiền mặt',
    @DanhSachVe     NVARCHAR(MAX),      -- JSON array
    -- Thông tin người đặt vé (chỉ cần họ tên và CMND)
    @NguoiDat_HoTen     NVARCHAR(50),
    @NguoiDat_CMND      NCHAR(12),
    -- Output
    @MaDonMoi       NCHAR(10) OUTPUT,
    @ThongBao       NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;  -- ✅ LOCK để tránh lost update
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- =============================================
        -- VALIDATE ĐẦU VÀO
        -- =============================================
        
        -- Kiểm tra phương thức thanh toán
        IF @PhuongThucTT NOT IN (N'Tiền mặt', N'Chuyển khoản')
        BEGIN
            SET @ThongBao = N'Phương thức thanh toán không hợp lệ';
            ROLLBACK TRANSACTION;
            RETURN -1056;
        END
        
        -- Kiểm tra nhân viên bán vé
        IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNVBanVe AND ChucVu = 'BV')
        BEGIN
            SET @ThongBao = N'Nhân viên bán vé không tồn tại hoặc không có quyền';
            ROLLBACK TRANSACTION;
            RETURN -1057;
        END
        
        -- Kiểm tra chuyến tàu
        IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
        BEGIN
            SET @ThongBao = N'Chuyến tàu không tồn tại';
            ROLLBACK TRANSACTION;
            RETURN -1009;
        END
        
        -- Kiểm tra ga đi và ga đến
        DECLARE @TrinhTuDi INT, @TrinhTuDen INT;
        
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
        
        -- =============================================
        -- TẠO HOẶC LẤY KHÁCH HÀNG NGƯỜI ĐẶT VÉ
        -- =============================================
        DECLARE @MaKH_NguoiDat NCHAR(10);
        DECLARE @ThongBaoKH NVARCHAR(200);
        DECLARE @RetCodeKH INT;
        
        -- Kiểm tra xem khách hàng đã tồn tại chưa (theo CMND trong NGUOI_DUNG)
        SELECT @MaKH_NguoiDat = kh.MaKH 
        FROM KHACH_HANG kh
        INNER JOIN NGUOI_DUNG nd ON kh.MaKH = nd.MaNguoiDung
        WHERE nd.CMND = @NguoiDat_CMND;
        
        -- Nếu chưa có, tạo mới
        IF @MaKH_NguoiDat IS NULL
        BEGIN
            EXEC @RetCodeKH = usp_ThemKhachHangTam
                @HoTen = @NguoiDat_HoTen,
                @CMND = @NguoiDat_CMND,
                @SDT = NULL,        -- Không bắt buộc
                @NgSinh = NULL,     -- Không bắt buộc
                @DiaChi = NULL,     -- Không bắt buộc
                @MaKH = @MaKH_NguoiDat OUTPUT,
                @ThongBao = @ThongBaoKH OUTPUT;
            
            IF @RetCodeKH <> 0
            BEGIN
                SET @ThongBao = N'Lỗi tạo khách hàng người đặt: ' + @ThongBaoKH;
                ROLLBACK TRANSACTION;
                RETURN @RetCodeKH;
            END
        END
        
        -- =============================================
        -- PARSE JSON VÀ TỰ ĐỘNG TẠO KHÁCH HÀNG TẠM
        -- =============================================
        DECLARE @VeTable TABLE (
            MaToa NCHAR(5),
            MaCho NCHAR(6),
            MaThamSo NCHAR(5),
            HoTen NVARCHAR(50),
            CMND NCHAR(12),
            SDT NCHAR(10),
            NgSinh DATE,
            DiaChi NVARCHAR(100),
            MaKH NCHAR(10)
        );
        
        INSERT INTO @VeTable (MaToa, MaCho, MaThamSo, HoTen, CMND, SDT, NgSinh, DiaChi)
        SELECT 
            JSON_VALUE(value, '$.maToa'),
            JSON_VALUE(value, '$.maCho'),
            JSON_VALUE(value, '$.maThamSo'),
            JSON_VALUE(value, '$.hoTen'),
            JSON_VALUE(value, '$.cmnd'),
            JSON_VALUE(value, '$.sdt'),
            TRY_CAST(JSON_VALUE(value, '$.ngSinh') AS DATE),
            JSON_VALUE(value, '$.diaChi')
        FROM OPENJSON(@DanhSachVe);
        
        -- Tạo khách hàng tạm cho từng hành khách
        DECLARE @HoTen NVARCHAR(50), @CMND NCHAR(12), @MaKH NCHAR(10);
        DECLARE @SDT NCHAR(10), @NgSinh DATE, @DiaChi NVARCHAR(100);
        DECLARE @ThongBaoTam NVARCHAR(200);
        DECLARE @RetCodeTam INT;
        
        DECLARE cur_TaoKH CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT HoTen, CMND, SDT, NgSinh, DiaChi FROM @VeTable;
        
        OPEN cur_TaoKH;
        FETCH NEXT FROM cur_TaoKH INTO @HoTen, @CMND, @SDT, @NgSinh, @DiaChi;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Kiểm tra khách hàng đã tồn tại chưa (qua NGUOI_DUNG)
            SELECT @MaKH = kh.MaKH 
            FROM KHACH_HANG kh
            INNER JOIN NGUOI_DUNG nd ON kh.MaKH = nd.MaNguoiDung
            WHERE nd.CMND = @CMND;
            
            IF @MaKH IS NULL
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
            END
            
            UPDATE @VeTable SET MaKH = @MaKH WHERE CMND = @CMND;
            FETCH NEXT FROM cur_TaoKH INTO @HoTen, @CMND, @SDT, @NgSinh, @DiaChi;
        END
        
        CLOSE cur_TaoKH;
        DEALLOCATE cur_TaoKH;
        
        -- =============================================
        -- VALIDATE SỐ LƯỢNG VÉ
        -- =============================================
        DECLARE @SoLuongVe INT;
        SELECT @SoLuongVe = COUNT(*) FROM @VeTable;
        
        IF @SoLuongVe = 0
        BEGIN
            SET @ThongBao = N'Danh sách vé trống';
            ROLLBACK TRANSACTION;
            RETURN -1052;
        END
        
        DECLARE @SoVeToiDa INT;
        SELECT @SoVeToiDa = GiaTriThamSo FROM THAM_SO WHERE MaThamSo = 'TS001';
        
        IF @SoLuongVe > @SoVeToiDa
        BEGIN
            SET @ThongBao = N'Vượt quá ' + CAST(@SoVeToiDa AS NVARCHAR(10)) + N' vé/đơn';
            ROLLBACK TRANSACTION;
            RETURN -1053;
        END
        
        -- =============================================
        -- ✅ KIỂM TRA VÀ LOCK GHẾ (SERIALIZABLE)
        -- =============================================
        DECLARE @MaToa NCHAR(5), @MaCho NCHAR(6), @MaThamSo NCHAR(5);
        DECLARE @ConTrong BIT;
        DECLARE @ThongBaoGhe NVARCHAR(200);
        DECLARE @RetCode INT;
        
        DECLARE cur_KiemTraGhe CURSOR LOCAL FAST_FORWARD FOR 
            SELECT DISTINCT MaToa, MaCho FROM @VeTable;
        
        OPEN cur_KiemTraGhe;
        FETCH NEXT FROM cur_KiemTraGhe INTO @MaToa, @MaCho;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- ✅ Kiểm tra VÀ LOCK ghế
            EXEC @RetCode = usp_KiemTraGheTrong
                @MaChuyenTau, @MaToa, @MaCho, @MaGaDi, @MaGaDen, 
                @ConTrong OUTPUT, @ThongBaoGhe OUTPUT;
            
            IF @RetCode <> 0 OR @ConTrong = 0
            BEGIN
                CLOSE cur_KiemTraGhe;
                DEALLOCATE cur_KiemTraGhe;
                SET @ThongBao = N'Ghế ' + RTRIM(@MaCho) + N' toa ' + RTRIM(@MaToa) + N' đã được đặt';
                ROLLBACK TRANSACTION;
                RETURN -1054;
            END
            
            FETCH NEXT FROM cur_KiemTraGhe INTO @MaToa, @MaCho;
        END
        
        CLOSE cur_KiemTraGhe;
        DEALLOCATE cur_KiemTraGhe;
        
        -- =============================================
        -- VALIDATE THAM SỐ (ĐỐI TƯỢNG)
        -- =============================================
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
        
        -- =============================================
        -- TÍNH TỔNG TIỀN
        -- =============================================
        DECLARE @TongTien DECIMAL(12,2) = 0;
        DECLARE @GiaVe DECIMAL(12,2);
        
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
        
        -- =============================================
        -- TẠO MÃ ĐƠN ĐẶT VÉ
        -- =============================================
        DECLARE @SoDon INT;
        SET @SoDon = NEXT VALUE FOR SEQ_MA_DON_DAT_VE;
        SET @MaDonMoi = N'DH' + RIGHT(N'000000' + CAST(@SoDon AS NVARCHAR), 6);
        
        -- =============================================
        -- TẠO ĐƠN ĐẶT VÉ (CÓ MÃ NHÂN VIÊN BÁN VÉ)
        -- =============================================
        INSERT INTO DON_DAT_VE (
            MaDon, ThoiGianDatve, TongTien, 
            MaChuyenTau, MaGaDi, MaGaDen, 
            MaNVBanVe, MaKH
        )
        VALUES (
            @MaDonMoi, 
            CONVERT(DATETIME, CONVERT(VARCHAR(19), GETDATE(), 120)), 
            @TongTien,
            @MaChuyenTau, @MaGaDi, @MaGaDen,
            @MaNVBanVe,         -- ✅ Có mã nhân viên bán vé
            @MaKH_NguoiDat
        );
        
        IF @@ERROR <> 0
        BEGIN
            SET @ThongBao = N'Lỗi khi tạo đơn đặt vé';
            ROLLBACK TRANSACTION;
            RETURN -9001;
        END
        
        -- =============================================
        -- TẠO CHI TIẾT VÉ (TRẠNG THÁI: ĐÃ THANH TOÁN)
        -- =============================================
        DECLARE @MaVeMoi NCHAR(12);
        DECLARE @KhuyenMai DECIMAL(12,2);
        DECLARE @ThanhTien DECIMAL(12,2);
        
        DECLARE cur_TaoVe CURSOR LOCAL FAST_FORWARD FOR 
            SELECT MaToa, MaCho, MaThamSo, MaKH FROM @VeTable;
        
        OPEN cur_TaoVe;
        FETCH NEXT FROM cur_TaoVe INTO @MaToa, @MaCho, @MaThamSo, @MaKH;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @SoVe INT;
            SET @SoVe = NEXT VALUE FOR SEQ_MA_VE;
            SET @MaVeMoi = N'VEDH' + RIGHT(N'000000' + CAST(@SoVe AS NVARCHAR), 6);

            SET @GiaVe = dbo.fn_TinhGiaVe(@MaChuyenTau, @MaToa, @MaCho, @MaGaDi, @MaGaDen);
            SET @KhuyenMai = dbo.fn_TinhGiamGiaTheoThamSo(@GiaVe, @MaThamSo);
            SET @ThanhTien = @GiaVe - @KhuyenMai;
            
            INSERT INTO CHI_TIET_VE (
                MaVe, ThoiGianXuatVe, TrangThai, KhuyenMai, PhuPhi, 
                DoiTuong, ThanhTien, PhuongThucTT, 
                MaToa, MaCho, MaDon, MaKH
            )
            VALUES (
                @MaVeMoi, 
                CONVERT(DATETIME, CONVERT(VARCHAR(19), GETDATE(), 120)),  -- ✅ Xuất vé ngay
                N'Đã thanh toán',  -- ✅ Trạng thái đã thanh toán (khác với online)
                @KhuyenMai, 
                0,
                @MaThamSo, 
                @ThanhTien, 
                @PhuongThucTT,
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
        
        SET @ThongBao = N'Đặt vé thành công cho ' + CAST(@SoLuongVe AS NVARCHAR(10)) + N' người. Tổng tiền: ' + FORMAT(@TongTien, 'N0') + N' VNĐ';
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
