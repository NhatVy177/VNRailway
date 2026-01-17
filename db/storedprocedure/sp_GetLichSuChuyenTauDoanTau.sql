USE VNRAILWAY
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
    
    -- Kiểm tra đoàn tàu
    IF NOT EXISTS (SELECT 1 FROM DOAN_TAU WHERE MaDoanTau = @MaDoanTau)
    BEGIN
        SET @ThongBao = N'Không tìm thấy đoàn tàu: ' + @MaDoanTau;
        RETURN -1;
    END
    
    -- [FIX QUAN TRỌNG] Mở rộng thời gian mặc định
    -- Nếu không truyền ngày, lấy từ năm 2000 để chắc chắn hiện hết dữ liệu test
    IF @TuNgay IS NULL
        SET @TuNgay = '2000-01-01'; 
    
    IF @DenNgay IS NULL
        SET @DenNgay = DATEADD(YEAR, 10, GETDATE()); -- Cộng thêm 10 năm để lấy cả chuyến tương lai
    
    DECLARE @Offset INT = (@Trang - 1) * @KichThuocTrang;
    
    -- Đếm tổng số
    SELECT @SoKetQua = COUNT(*)
    FROM CHUYEN_TAU ct
    WHERE ct.MaDoanTau = @MaDoanTau
        AND ct.ThoiGianXuatPhat BETWEEN @TuNgay AND @DenNgay;
    
    -- Lấy dữ liệu
    SELECT 
        ct.MaChuyenTau,
        ct.ThoiGianXuatPhat,
        ISNULL(t.MaTuyen, 'N/A') AS MaTuyen, -- Xử lý null nếu thiếu tuyến
        ISNULL(t.TenTuyen, N'Chưa phân tuyến') AS TenTuyen,
        
        -- Tính khoảng cách
        ISNULL((SELECT SUM(KhoangCach) FROM TUYEN_GA WHERE MaTuyen = t.MaTuyen), 0) AS KhoangCach,
        
        ISNULL(gaDi.TenGa, N'Chưa có') AS GaDi,
        ISNULL(gaDen.TenGa, N'Chưa có') AS GaDen,
        
        CASE 
            WHEN GETDATE() < ct.ThoiGianXuatPhat THEN 'S' 
            WHEN GETDATE() > ct.ThoiGianDuKienDen THEN 'F' 
            ELSE 'R' 
        END AS TrangThai,
        
        CASE 
            WHEN GETDATE() < ct.ThoiGianXuatPhat THEN N'⏰ Chưa khởi hành'
            WHEN GETDATE() > ct.ThoiGianDuKienDen THEN N'✅ Đã hoàn thành'
            ELSE N'🚂 Đang chạy'
        END AS MoTaTrangThai,

        (SELECT COUNT(*) 
         FROM CHI_TIET_VE ctv
         JOIN DON_DAT_VE ddv ON ctv.MaDon = ddv.MaDon
         WHERE ddv.MaChuyenTau = ct.MaChuyenTau 
           AND ctv.TrangThai = N'Đã thanh toán') AS SoVeBan,
        
        (SELECT COUNT(*) FROM PHANCONG_LAITAU pl WHERE pl.MaChuyenTau = ct.MaChuyenTau) AS SoLaiTau,
        (SELECT COUNT(*) FROM PHANCONG_TOA pt WHERE pt.MaChuyenTau = ct.MaChuyenTau) AS SoNhanVienPhucVu

    FROM CHUYEN_TAU ct
    -- [FIX] Dùng LEFT JOIN để lỡ sai mã tuyến vẫn hiện chuyến tàu
    LEFT JOIN TUYEN t ON ct.MaTuyen = t.MaTuyen
    
    LEFT JOIN (
        SELECT cg.MaChuyenTau, g.TenGa
        FROM CHUYEN_GA cg
        JOIN GA g ON cg.MaGa = g.MaGa
        WHERE cg.TrinhTu = 1
    ) gaDi ON ct.MaChuyenTau = gaDi.MaChuyenTau
    
    LEFT JOIN (
        SELECT cg.MaChuyenTau, g.TenGa
        FROM CHUYEN_GA cg
        JOIN GA g ON cg.MaGa = g.MaGa
        WHERE cg.TrinhTu = (
            SELECT MAX(cg2.TrinhTu) FROM CHUYEN_GA cg2 WHERE cg2.MaChuyenTau = cg.MaChuyenTau
        )
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