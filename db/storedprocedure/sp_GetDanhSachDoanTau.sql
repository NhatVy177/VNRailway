/*
    Stored Procedure: sp_GetDanhSachDoanTau
    Mục đích: Lấy danh sách đoàn tàu với thông tin chi tiết và phân trang
*/
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
    
    -- Xử lý chuỗi rỗng thành NULL
    IF @LoaiTau = '' OR LTRIM(RTRIM(@LoaiTau)) = '' SET @LoaiTau = NULL;
    IF @TimKiem = '' OR LTRIM(RTRIM(@TimKiem)) = '' SET @TimKiem = NULL;
    
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
