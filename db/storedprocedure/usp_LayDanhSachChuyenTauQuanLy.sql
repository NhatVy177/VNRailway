USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_LayDanhSachChuyenTauQuanLy
-- Lấy danh sách chuyến tàu cho quản lý phân công
-- =============================================
CREATE OR ALTER PROC usp_LayDanhSachChuyenTauQuanLy
    @MaChuyenTau     NCHAR(10) = NULL,
    @NgayKhoiHanhTu  DATE      = NULL,
    @NgayKhoiHanhDen DATE      = NULL,
    @LoaiTau         NCHAR(1)  = NULL,
    @TrangThai       NVARCHAR(50) = NULL,
    @ThongBao        NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý chuỗi rỗng thành NULL
    IF @MaChuyenTau = '' OR LTRIM(RTRIM(@MaChuyenTau)) = '' SET @MaChuyenTau = NULL;
    IF @LoaiTau = '' OR LTRIM(RTRIM(@LoaiTau)) = '' SET @LoaiTau = NULL;
    IF @TrangThai = '' OR LTRIM(RTRIM(@TrangThai)) = '' SET @TrangThai = NULL;

    -- Bảng tạm lưu kết quả
    DECLARE @KetQua TABLE (
        MaChuyenTau         NCHAR(10),
        MaTuyen             NCHAR(4),
        TenTuyen            NVARCHAR(50),
        MaDoanTau           NCHAR(4),
        TenTau              NVARCHAR(50),
        LoaiTau             NCHAR(1),
        ThoiGianXuatPhat    DATETIME,
        ThoiGianDuKienDen   DATETIME,
        TongSoViTri         INT,
        SoPhanCongDaCo      INT,
        SoNghiPhep          INT,
        SoConThieu          INT,
        TrangThaiPhanCong   NVARCHAR(50),
        LaChuyenTuongLai    BIT
    );

    -- Lấy dữ liệu chuyến tàu
    INSERT INTO @KetQua
    SELECT
        CT.MaChuyenTau,
        CT.MaTuyen,
        T.TenTuyen,
        CT.MaDoanTau,
        DT.TenTau,
        DT.LoaiTau,
        CT.ThoiGianXuatPhat,
        CT.ThoiGianDuKienDen,
        
        -- Tổng số vị trí cần phân công (2 lái tàu + 1 Trưởng toa + số toa nhân viên)
        3 + (SELECT COUNT(*) FROM TOA_TAU TT WHERE TT.MaDoanTau = CT.MaDoanTau) AS TongSoViTri,
        
        -- Số phân công đã có (không tính nghỉ phép)
        (SELECT COUNT(DISTINCT MaNV)
         FROM (
             SELECT MaNV FROM PHANCONG_LAITAU 
             WHERE MaChuyenTau = CT.MaChuyenTau AND TrangThai <> N'Nghỉ phép'
             UNION ALL
             SELECT MaNV FROM PHANCONG_TOA 
             WHERE MaChuyenTau = CT.MaChuyenTau AND TrangThai <> N'Nghỉ phép'
         ) x) AS SoPhanCongDaCo,
        
        -- Số nghỉ phép
        (SELECT COUNT(*)
         FROM (
             SELECT MaNV FROM PHANCONG_LAITAU 
             WHERE MaChuyenTau = CT.MaChuyenTau AND TrangThai = N'Nghỉ phép'
             UNION ALL
             SELECT MaNV FROM PHANCONG_TOA 
             WHERE MaChuyenTau = CT.MaChuyenTau AND TrangThai = N'Nghỉ phép'
         ) y) AS SoNghiPhep,
        
        -- Số còn thiếu
        (3 + (SELECT COUNT(*) FROM TOA_TAU TT WHERE TT.MaDoanTau = CT.MaDoanTau)) 
        - (SELECT COUNT(DISTINCT MaNV)
           FROM (
               SELECT MaNV FROM PHANCONG_LAITAU 
               WHERE MaChuyenTau = CT.MaChuyenTau AND TrangThai <> N'Nghỉ phép'
               UNION ALL
               SELECT MaNV FROM PHANCONG_TOA 
               WHERE MaChuyenTau = CT.MaChuyenTau AND TrangThai <> N'Nghỉ phép'
           ) x) AS SoConThieu,
        
        -- Trạng thái phân công
        CASE 
            WHEN (3 + (SELECT COUNT(*) FROM TOA_TAU TT WHERE TT.MaDoanTau = CT.MaDoanTau)) 
                 = (SELECT COUNT(DISTINCT MaNV)
                    FROM (
                        SELECT MaNV FROM PHANCONG_LAITAU 
                        WHERE MaChuyenTau = CT.MaChuyenTau AND TrangThai <> N'Nghỉ phép'
                        UNION ALL
                        SELECT MaNV FROM PHANCONG_TOA 
                        WHERE MaChuyenTau = CT.MaChuyenTau AND TrangThai <> N'Nghỉ phép'
                    ) x)
            THEN N'Đủ phân công'
            ELSE N'Chưa đủ phân công'
        END AS TrangThaiPhanCong,
        
        -- Chuyến tương lai hay quá khứ
        CASE 
            WHEN CT.ThoiGianXuatPhat > GETDATE() THEN 1
            ELSE 0
        END AS LaChuyenTuongLai
        
    FROM CHUYEN_TAU CT
    JOIN TUYEN T ON CT.MaTuyen = T.MaTuyen
    JOIN DOAN_TAU DT ON CT.MaDoanTau = DT.MaDoanTau
    WHERE (@MaChuyenTau IS NULL OR CT.MaChuyenTau LIKE '%' + LTRIM(RTRIM(@MaChuyenTau)) + '%')
      AND (@LoaiTau IS NULL OR DT.LoaiTau = @LoaiTau)
      AND (@NgayKhoiHanhTu IS NULL OR CAST(CT.ThoiGianXuatPhat AS DATE) >= @NgayKhoiHanhTu)
      AND (@NgayKhoiHanhDen IS NULL OR CAST(CT.ThoiGianXuatPhat AS DATE) <= @NgayKhoiHanhDen);

    -- Lọc theo trạng thái phân công (chỉ lọc khi có giá trị)
    IF @TrangThai IS NOT NULL
    BEGIN
        DELETE FROM @KetQua
        WHERE TrangThaiPhanCong <> @TrangThai;
    END

    -- Trả về kết quả với sắp xếp
    SELECT *
    FROM @KetQua
    ORDER BY 
        LaChuyenTuongLai DESC,
        CASE WHEN TrangThaiPhanCong = N'Chưa đủ phân công' THEN 0 ELSE 1 END ASC,
        ThoiGianXuatPhat ASC;

    SET @ThongBao = N'Lấy danh sách chuyến tàu thành công.';
    RETURN 0;
END
GO
