USE VNRAILWAY
GO

/* =============================================
   Procedure: usp_TaoDonDatVe_Online_FIX
   Mô tả: PHIÊN BẢN HOÀN CHỈNH - ĐÃ SỬA LỖI UNREPEATABLE READ
   Giải pháp: Nâng Isolation Level lên REPEATABLE READ để giữ Shared Lock trên bảng THAM_SO
   ============================================= */
CREATE OR ALTER PROC usp_TaoDonDatVe_Online_FIX
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
    
    --  1. THIẾT LẬP MỨC CÔ LẬP: REPEATABLE READ
    -- Các dữ liệu được đọc (SELECT) sẽ bị khóa Shared Lock (S) cho đến khi Transaction kết thúc.
    -- Điều này ngăn cản Transaction khác sửa đổi (Update/Delete) dữ liệu đó.
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 2. Validate cơ bản
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
        
        -- Kiểm tra trình tự ga
        DECLARE @TrinhTuDi int, @TrinhTuDen int;
        
        SELECT @TrinhTuDi = TrinhTu FROM CHUYEN_GA WHERE MaChuyenTau = @MaChuyenTau AND MaGa = @MaGaDi;
        SELECT @TrinhTuDen = TrinhTu FROM CHUYEN_GA WHERE MaChuyenTau = @MaChuyenTau AND MaGa = @MaGaDen;
        
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

        -- 3. Parse JSON và xử lý danh sách vé
        DECLARE @VeTable TABLE (
            MaToa nchar(5),
            MaCho nchar(6),
            MaThamSo nchar(5),
            HoTen nvarchar(50),
            CMND nchar(12),
            SDT nchar(10),
            NgSinh date,
            DiaChi nvarchar(100),
            MaKH nchar(10) -- Sẽ được điền sau
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
        
        DECLARE @SoLuongVe int;
        SELECT @SoLuongVe = COUNT(*) FROM @VeTable;
        
        IF @SoLuongVe = 0
        BEGIN
            SET @ThongBao = N'Danh sách vé trống';
            ROLLBACK TRANSACTION;
            RETURN -1052;
        END

        -- 4. Xử lý khách hàng tạm (Tự động tạo nếu chưa có)
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
                @HoTen = @HoTen, @CMND = @CMND, @SDT = @SDT, @NgSinh = @NgSinh, @DiaChi = @DiaChi,
                @MaKH = @MaKH OUTPUT, @ThongBao = @ThongBaoTam OUTPUT;
            
            IF @RetCodeTam <> 0
            BEGIN
                CLOSE cur_TaoKH; DEALLOCATE cur_TaoKH;
                SET @ThongBao = N'Lỗi tạo khách hàng tạm: ' + @ThongBaoTam;
                ROLLBACK TRANSACTION;
                RETURN @RetCodeTam;
            END
            
            UPDATE @VeTable SET MaKH = @MaKH WHERE CMND = @CMND;
            FETCH NEXT FROM cur_TaoKH INTO @HoTen, @CMND, @SDT, @NgSinh, @DiaChi;
        END
        CLOSE cur_TaoKH; DEALLOCATE cur_TaoKH;

        -- =============================================
        --  5. KIỂM TRA QUY ĐỊNH SỐ VÉ TỐI ĐA (FIXED)
        -- =============================================
        -- Do Isolation Level = REPEATABLE READ, lệnh SELECT này sẽ:
        -- 1. Đọc giá trị TS001
        -- 2. Giữ Shared Lock trên dòng TS001 cho đến khi Transaction này COMMIT/ROLLBACK
        -- -> Ngăn chặn Transaction khác sửa đổi TS001 trong lúc này.
        
        DECLARE @SoVeToiDa int;
        SELECT @SoVeToiDa = GiaTriThamSo 
        FROM THAM_SO 
        WHERE MaThamSo = 'TS001';
        
        IF @SoLuongVe > @SoVeToiDa
        BEGIN
            SET @ThongBao = N'Vượt quá số lượng vé tối đa cho phép (' + CAST(@SoVeToiDa AS nvarchar(10)) + N' vé).';
            ROLLBACK TRANSACTION;
            RETURN -1053;
        END
        
        --  WAITFOR DELAY: Để minh họa việc giữ khóa
        -- Trong 10 giây này, nếu Admin chạy sp_UpdateThamSo sửa TS001, Admin sẽ bị TREO (Waiting).
        WAITFOR DELAY '00:00:10';

        -- 6. Kiểm tra ghế trống
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
            EXEC @RetCode = usp_KiemTraGheTrong 
                @MaChuyenTau, @MaToa, @MaCho, @MaGaDi, @MaGaDen, 
                @ConTrong OUTPUT, @ThongBaoGhe OUTPUT;
            
            IF @RetCode <> 0 OR @ConTrong = 0
            BEGIN
                CLOSE cur_KiemTraGhe; DEALLOCATE cur_KiemTraGhe;
                SET @ThongBao = N'Ghế ' + RTRIM(@MaCho) + N' toa ' + RTRIM(@MaToa) + N' đã được đặt hoặc không hợp lệ.';
                ROLLBACK TRANSACTION;
                RETURN -1054;
            END
            FETCH NEXT FROM cur_KiemTraGhe INTO @MaToa, @MaCho;
        END
        CLOSE cur_KiemTraGhe; DEALLOCATE cur_KiemTraGhe;

        -- 7. Tính tổng tiền
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
        CLOSE cur_TinhTien; DEALLOCATE cur_TinhTien;
        
        -- 8. Tạo đơn đặt vé (Header)
        DECLARE @SoDon int = NEXT VALUE FOR SEQ_MA_DON_DAT_VE;
        SET @MaDonMoi = N'DH' + RIGHT(N'000000' + CAST(@SoDon AS nvarchar), 6);
        
        INSERT INTO DON_DAT_VE (MaDon, ThoiGianDatve, TongTien, MaChuyenTau, MaGaDi, MaGaDen, MaKH)
        VALUES (@MaDonMoi, GETDATE(), @TongTien, @MaChuyenTau, @MaGaDi, @MaGaDen, @MaKH_NguoiDat);
        
        IF @@ERROR <> 0
        BEGIN
            SET @ThongBao = N'Lỗi khi tạo đơn đặt vé';
            ROLLBACK TRANSACTION;
            RETURN -9001;
        END
        
        -- 9. Tạo chi tiết vé (Detail)
        DECLARE @MaVeMoi nchar(12);
        DECLARE @KhuyenMai decimal(12,2);
        DECLARE @ThanhTien decimal(12,2);
        
        DECLARE cur_TaoVe CURSOR LOCAL FAST_FORWARD FOR 
            SELECT MaToa, MaCho, MaThamSo, MaKH FROM @VeTable;
        
        OPEN cur_TaoVe;
        FETCH NEXT FROM cur_TaoVe INTO @MaToa, @MaCho, @MaThamSo, @MaKH;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @SoVe int = NEXT VALUE FOR SEQ_MA_VE;
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
                CLOSE cur_TaoVe; DEALLOCATE cur_TaoVe;
                SET @ThongBao = N'Lỗi khi tạo chi tiết vé';
                ROLLBACK TRANSACTION;
                RETURN -9002;
            END
            
            FETCH NEXT FROM cur_TaoVe INTO @MaToa, @MaCho, @MaThamSo, @MaKH;
        END
        CLOSE cur_TaoVe; DEALLOCATE cur_TaoVe;
        
        --  COMMIT: Giải phóng Lock trên bảng THAM_SO
        COMMIT TRANSACTION;
        
        SET @ThongBao = N'Đặt vé thành công (FIXED).';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ThongBao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        RETURN -9999;
    END CATCH
END
GO

DECLARE @MaDon nchar(10), @ThongBao nvarchar(200);
DECLARE @RetCode int;

EXEC @RetCode = usp_TaoDonDatVe_Online_FIX
    @MaChuyenTau = 'VNW1E8BEE6',
    @MaGaDi = 'GA009',
    @MaGaDen = 'GA008',
    @MaKH_NguoiDat = 'U000001',
    @PhuongThucTT = N'Tiền mặt',
    @DanhSachVe = N'[
  {
    "maToa": "T0066", "maCho": "GIB013", "maThamSo": "TS009",
    "hoTen": "Nguyễn Văn An", "cmnd": "001341972210"
  },
  {
    "maToa": "T0066", "maCho": "GIB014", "maThamSo": "TS010",
    "hoTen": "Lê Văn Cường", "cmnd": "086872678432"
  },
  {
    "maToa": "T0066", "maCho": "GIB015", "maThamSo": "TS010",
    "hoTen": "Lê Văn Hùng", "cmnd": "001653282944"
  }
]',
    @MaDonMoi = @MaDon OUTPUT,
    @ThongBao = @ThongBao OUTPUT;

PRINT N'Return Code: ' + CAST(@RetCode AS nvarchar(10));
PRINT N'Mã đơn: ' + ISNULL(@MaDon, 'NULL');
PRINT N'Thông báo: ' + @ThongBao;
GO