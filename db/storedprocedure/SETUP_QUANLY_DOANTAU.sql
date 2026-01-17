-- =============================================
-- SCRIPT CÀI ĐẶT STORED PROCEDURES QUẢN LÝ ĐOÀN TÀU
-- Chạy script này trong SQL Server để tạo tất cả các stored procedures
-- =============================================

USE VNRAILWAY;
GO

PRINT '================================================';
PRINT 'BẮT ĐẦU CÀI ĐẶT STORED PROCEDURES QUẢN LÝ ĐOÀN TÀU';
PRINT '================================================';
PRINT '';

-- =============================================
-- 1. sp_GetDanhSachDoanTau
-- =============================================
PRINT '1. Đang tạo sp_GetDanhSachDoanTau...';
GO

CREATE OR ALTER PROC sp_GetDanhSachDoanTau
    @LoaiTau NCHAR(1) = NULL,
    @TimKiem NVARCHAR(100) = NULL,
    @Trang INT = 1,
    @KichThuocTrang INT = 10,
    @SoKetQua INT OUTPUT,
    @ThongBao NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Lấy tham số giới hạn km
    DECLARE @KmToiThieu DECIMAL(12,2), @KmToiDa DECIMAL(12,2);
    
    SELECT @KmToiThieu = GiaTriThamSo 
    FROM THAM_SO 
    WHERE MaThamSo = 'TS014';
    
    SELECT @KmToiDa = GiaTriThamSo 
    FROM THAM_SO 
    WHERE MaThamSo = 'TS015';
    
    -- Tính offset
    DECLARE @Offset INT = (@Trang - 1) * @KichThuocTrang;
    
    -- Đếm tổng số bản ghi
    SELECT @SoKetQua = COUNT(*)
    FROM DOAN_TAU dt
    WHERE (@LoaiTau IS NULL OR dt.LoaiTau = @LoaiTau)
        AND (@TimKiem IS NULL OR dt.MaDoanTau LIKE '%' + @TimKiem + '%' 
             OR dt.TenTau LIKE '%' + @TimKiem + '%'
             OR dt.HangSX LIKE '%' + @TimKiem + '%');
    
    -- Lấy danh sách đoàn tàu với phân trang
    SELECT 
        dt.MaDoanTau,
        dt.TenTau,
        dt.HangSX,
        dt.NgVanHanh,
        DATEDIFF(YEAR, dt.NgVanHanh, GETDATE()) AS SoNamHoatDong,
        dt.LoaiTau,
        CASE dt.LoaiTau 
            WHEN 'S' THEN N'Tàu nhanh'
            WHEN 'T' THEN N'Tàu thường'
            ELSE N'Không xác định'
        END AS TenLoaiTau,
        (SELECT COUNT(*) FROM TOA_TAU WHERE MaDoanTau = dt.MaDoanTau) AS SoToaTau,
        dbo.fn_TinhTongKmDoanTauTrongTuan(dt.MaDoanTau, GETDATE()) AS KmTrongTuan,
        @KmToiThieu AS KmToiThieu,
        @KmToiDa AS KmToiDa,
        CASE 
            WHEN dbo.fn_TinhTongKmDoanTauTrongTuan(dt.MaDoanTau, GETDATE()) < @KmToiThieu THEN 'DUOI_MIN'
            WHEN dbo.fn_TinhTongKmDoanTauTrongTuan(dt.MaDoanTau, GETDATE()) > @KmToiDa THEN 'VUOT_MAX'
            ELSE 'BINH_THUONG'
        END AS TrangThaiKm,
        CASE 
            WHEN dbo.fn_TinhTongKmDoanTauTrongTuan(dt.MaDoanTau, GETDATE()) < @KmToiThieu THEN N'⚠️ Dưới mức tối thiểu'
            WHEN dbo.fn_TinhTongKmDoanTauTrongTuan(dt.MaDoanTau, GETDATE()) > @KmToiDa THEN N'❌ Vượt quá giới hạn'
            ELSE N'✅ Hoạt động bình thường'
        END AS MoTaTrangThai,
        (SELECT COUNT(*) 
         FROM CHUYEN_TAU ct 
         WHERE ct.MaDoanTau = dt.MaDoanTau 
           AND ct.ThoiGianXuatPhat >= DATEADD(DAY, -7, GETDATE())) AS SoChuyenTrongTuan,
        STUFF((
            SELECT DISTINCT ', ' + t.TenTuyen
            FROM TUYEN_DOANTAU td
            JOIN TUYEN t ON td.MaTuyen = t.MaTuyen
            WHERE td.MaDoanTau = dt.MaDoanTau
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS CacTuyenDangPhucVu
    FROM DOAN_TAU dt
    WHERE (@LoaiTau IS NULL OR dt.LoaiTau = @LoaiTau)
        AND (@TimKiem IS NULL OR dt.MaDoanTau LIKE '%' + @TimKiem + '%' 
             OR dt.TenTau LIKE '%' + @TimKiem + '%'
             OR dt.HangSX LIKE '%' + @TimKiem + '%')
    ORDER BY dt.MaDoanTau
    OFFSET @Offset ROWS
    FETCH NEXT @KichThuocTrang ROWS ONLY;
    
    SET @ThongBao = N'Lấy danh sách đoàn tàu thành công';
    RETURN 0;
END;
GO

PRINT '   ✓ Đã tạo sp_GetDanhSachDoanTau';
PRINT '';

-- =============================================
-- 2. sp_ThemDoanTau
-- =============================================
PRINT '2. Đang tạo sp_ThemDoanTau...';
GO

CREATE OR ALTER PROC sp_ThemDoanTau
    @MaDoanTau NCHAR(4),
    @TenTau NVARCHAR(50),
    @HangSX NVARCHAR(50),
    @NgVanHanh DATE,
    @LoaiTau NCHAR(1),
    @ThongBao NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Kiểm tra mã đoàn tàu đã tồn tại
        IF EXISTS (SELECT 1 FROM DOAN_TAU WHERE MaDoanTau = @MaDoanTau)
        BEGIN
            SET @ThongBao = N'Mã đoàn tàu đã tồn tại: ' + @MaDoanTau;
            RETURN -1;
        END
        
        -- Kiểm tra loại tàu hợp lệ
        IF @LoaiTau NOT IN ('S', 'T')
        BEGIN
            SET @ThongBao = N'Loại tàu không hợp lệ. Chỉ chấp nhận S (tàu nhanh) hoặc T (tàu thường)';
            RETURN -2;
        END
        
        -- Kiểm tra ngày vận hành không được trong tương lai
        IF @NgVanHanh > GETDATE()
        BEGIN
            SET @ThongBao = N'Ngày vận hành không được trong tương lai';
            RETURN -3;
        END
        
        -- Thêm đoàn tàu mới
        INSERT INTO DOAN_TAU (MaDoanTau, TenTau, HangSX, NgVanHanh, LoaiTau)
        VALUES (@MaDoanTau, @TenTau, @HangSX, @NgVanHanh, @LoaiTau);
        
        COMMIT TRANSACTION;
        SET @ThongBao = N'✅ Thêm đoàn tàu thành công: ' + @MaDoanTau;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @ThongBao = N'❌ Lỗi: ' + ERROR_MESSAGE();
        RETURN -99;
    END CATCH
END;
GO

PRINT '   ✓ Đã tạo sp_ThemDoanTau';
PRINT '';

-- =============================================
-- 3. sp_CapNhatDoanTau
-- =============================================
PRINT '3. Đang tạo sp_CapNhatDoanTau...';
GO

CREATE OR ALTER PROC sp_CapNhatDoanTau
    @MaDoanTau NCHAR(4),
    @TenTau NVARCHAR(50) = NULL,
    @HangSX NVARCHAR(50) = NULL,
    @NgVanHanh DATE = NULL,
    @LoaiTau NCHAR(1) = NULL,
    @ThongBao NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Kiểm tra đoàn tàu có tồn tại
        IF NOT EXISTS (SELECT 1 FROM DOAN_TAU WHERE MaDoanTau = @MaDoanTau)
        BEGIN
            SET @ThongBao = N'Không tìm thấy đoàn tàu: ' + @MaDoanTau;
            RETURN -1;
        END
        
        -- Kiểm tra loại tàu hợp lệ (nếu được cập nhật)
        IF @LoaiTau IS NOT NULL AND @LoaiTau NOT IN ('S', 'T')
        BEGIN
            SET @ThongBao = N'Loại tàu không hợp lệ. Chỉ chấp nhận S (tàu nhanh) hoặc T (tàu thường)';
            RETURN -2;
        END
        
        -- Kiểm tra ngày vận hành không được trong tương lai (nếu được cập nhật)
        IF @NgVanHanh IS NOT NULL AND @NgVanHanh > GETDATE()
        BEGIN
            SET @ThongBao = N'Ngày vận hành không được trong tương lai';
            RETURN -3;
        END
        
        -- Cập nhật thông tin
        UPDATE DOAN_TAU
        SET 
            TenTau = ISNULL(@TenTau, TenTau),
            HangSX = ISNULL(@HangSX, HangSX),
            NgVanHanh = ISNULL(@NgVanHanh, NgVanHanh),
            LoaiTau = ISNULL(@LoaiTau, LoaiTau)
        WHERE MaDoanTau = @MaDoanTau;
        
        COMMIT TRANSACTION;
        SET @ThongBao = N'✅ Cập nhật thông tin đoàn tàu thành công: ' + @MaDoanTau;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @ThongBao = N'❌ Lỗi: ' + ERROR_MESSAGE();
        RETURN -99;
    END CATCH
END;
GO

PRINT '   ✓ Đã tạo sp_CapNhatDoanTau';
PRINT '';

-- =============================================
-- 4. sp_GetLichSuChuyenTauDoanTau
-- =============================================
PRINT '4. Đang tạo sp_GetLichSuChuyenTauDoanTau...';
GO

CREATE OR ALTER PROC sp_GetLichSuChuyenTauDoanTau
    @MaDoanTau NCHAR(4),
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL,
    @Trang INT = 1,
    @KichThuocTrang INT = 10,
    @SoKetQua INT OUTPUT,
    @ThongBao NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra đoàn tàu có tồn tại
    IF NOT EXISTS (SELECT 1 FROM DOAN_TAU WHERE MaDoanTau = @MaDoanTau)
    BEGIN
        SET @ThongBao = N'Không tìm thấy đoàn tàu: ' + @MaDoanTau;
        RETURN -1;
    END
    
    -- Nếu không có ngày, lấy 3 tháng gần nhất
    IF @TuNgay IS NULL
        SET @TuNgay = DATEADD(MONTH, -3, GETDATE());
    
    IF @DenNgay IS NULL
        SET @DenNgay = GETDATE();
    
    -- Tính offset
    DECLARE @Offset INT = (@Trang - 1) * @KichThuocTrang;
    
    -- Đếm tổng số chuyến
    SELECT @SoKetQua = COUNT(*)
    FROM CHUYEN_TAU ct
    WHERE ct.MaDoanTau = @MaDoanTau
        AND ct.ThoiGianXuatPhat BETWEEN @TuNgay AND @DenNgay;
    
    -- Lấy lịch sử chuyến tàu
    SELECT 
        ct.MaChuyenTau,
        ct.ThoiGianXuatPhat,
        t.MaTuyen,
        t.TenTuyen,
        t.ChieuDai AS KhoangCach,
        gaDi.TenGa AS GaDi,
        gaDen.TenGa AS GaDen,
        CASE 
            WHEN ct.ThoiGianXuatPhat > GETDATE() THEN N'C'
            ELSE N'Đ'
        END AS TrangThai,
        CASE 
            WHEN ct.ThoiGianXuatPhat > GETDATE() THEN N'⏰ Chưa khởi hành'
            ELSE N'✅ Đã hoàn thành'
        END AS MoTaTrangThai,
        ISNULL((SELECT COUNT(*) 
                FROM DON_DAT_VE ddv
                JOIN CHI_TIET_VE ctv ON ddv.MaDon = ctv.MaDon
                WHERE ddv.MaChuyenTau = ct.MaChuyenTau), 0) AS SoVeBan,
        ISNULL((SELECT COUNT(*) 
                FROM PHANCONG_LAITAU pl 
                WHERE pl.MaChuyenTau = ct.MaChuyenTau), 0) AS SoLaiTau,
        ISNULL((SELECT COUNT(*) 
                FROM PHANCONG_TOA pt 
                WHERE pt.MaChuyenTau = ct.MaChuyenTau), 0) AS SoNhanVienPhucVu
    FROM CHUYEN_TAU ct
    JOIN TUYEN t ON ct.MaTuyen = t.MaTuyen
    LEFT JOIN (
        SELECT cg.MaChuyenTau, MIN(g.TenGa) AS TenGa
        FROM CHUYEN_GA cg
        JOIN GA g ON cg.MaGa = g.MaGa
        WHERE cg.TrinhTu = 1
        GROUP BY cg.MaChuyenTau
    ) gaDi ON ct.MaChuyenTau = gaDi.MaChuyenTau
    LEFT JOIN (
        SELECT cg.MaChuyenTau, MAX(g.TenGa) AS TenGa
        FROM CHUYEN_GA cg
        JOIN GA g ON cg.MaGa = g.MaGa
        WHERE cg.TrinhTu = (
            SELECT MAX(cg2.TrinhTu) 
            FROM CHUYEN_GA cg2 
            WHERE cg2.MaChuyenTau = cg.MaChuyenTau
        )
        GROUP BY cg.MaChuyenTau
    ) gaDen ON ct.MaChuyenTau = gaDen.MaChuyenTau
    WHERE ct.MaDoanTau = @MaDoanTau
        AND ct.ThoiGianXuatPhat BETWEEN @TuNgay AND @DenNgay
    ORDER BY ct.ThoiGianXuatPhat DESC
    OFFSET @Offset ROWS
    FETCH NEXT @KichThuocTrang ROWS ONLY;
    
    SET @ThongBao = N'Lấy lịch sử chuyến tàu thành công';
    RETURN 0;
END;
GO

PRINT '   ✓ Đã tạo sp_GetLichSuChuyenTauDoanTau';
PRINT '';

-- =============================================
-- Kiểm tra kết quả
-- =============================================
PRINT '================================================';
PRINT 'HOÀN TẤT CÀI ĐẶT!';
PRINT '================================================';
PRINT '';
PRINT 'Danh sách stored procedures đã tạo:';
PRINT '  1. sp_GetDanhSachDoanTau';
PRINT '  2. sp_ThemDoanTau';
PRINT '  3. sp_CapNhatDoanTau';
PRINT '  4. sp_GetLichSuChuyenTauDoanTau';
PRINT '';
PRINT 'Để kiểm tra, chạy lệnh:';
PRINT '  SELECT * FROM sys.procedures WHERE name LIKE ''%DoanTau%''';
PRINT '';
PRINT '================================================';
GO
