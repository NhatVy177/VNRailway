USE VNRAILWAY
GO
/* =============================================
   PROCEDURE 1: sp_LayDanhSachNhanVienVaLuong
   FIX: Đổi điều kiện ChucVu
   ============================================= */
CREATE OR ALTER PROC sp_LayDanhSachNhanVienVaLuong
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @LoaiNV NVARCHAR(10) = NULL,
    @TimKiem NVARCHAR(100) = NULL,
    @SortBy NVARCHAR(20) = 'TongLuong',
    @SortOrder NVARCHAR(4) = 'DESC',
    @Thang INT = NULL,
    @Nam INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    WITH NhanVienData AS (
        SELECT 
            nv.MaNV,
            nd.HoTen,
            nd.SDT,
            nv.GioiTinh,
            
            -- Mapping mã loại nhân viên (ChucVu đã là mã rồi, không cần convert)
            nv.ChucVu as MaLoaiNV,
            
            -- Mapping tên hiển thị
            CASE 
                WHEN nv.ChucVu = 'LT' THEN N'Lái tàu'
                WHEN nv.ChucVu = 'TT' THEN N'Toa tàu'
                WHEN nv.ChucVu = 'AD' THEN N'Quản trị viên'
                WHEN nv.ChucVu = 'QL' THEN N'Quản lý'
                WHEN nv.ChucVu = 'BV' THEN N'Bán vé'
                ELSE nv.ChucVu
            END as TenLoaiNV,
            
            -- Thông tin chính sách lương
            ISNULL(csl.LuongCoBan, 0) as LuongCoBan,
            ISNULL(csl.PhuCap, 0) as PhuCap,
            ISNULL(csl.ThuLaoChuyen, 0) as ThuLaoChuyen,
            ISNULL(csl.ThuLaoThayThe, 0) as ThuLaoThayThe,
            ISNULL(csl.PhatNghiPhep, 0) as PhatNghiPhep,
            
            -- Số CHUYẾN đã làm - FIX: Đổi điều kiện từ N'Lái tàu' → 'LT' + Filter theo tháng/năm
            CASE 
                WHEN nv.ChucVu IN ('LT', 'TT') THEN
                    COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                              FROM PHANCONG_LAITAU pc 
                              INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                              WHERE pc.MaNV = nv.MaNV 
                              AND pc.TrangThai = N'Thực hiện'
                              AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                              AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                    COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                              FROM PHANCONG_TOA pc 
                              INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                              WHERE pc.MaNV = nv.MaNV 
                              AND pc.TrangThai = N'Thực hiện'
                              AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                              AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0)
                ELSE 0
            END as SoChuyenDaLam,
            
            -- Số CHUYẾN thay thế - FIX + Filter theo tháng/năm
            CASE 
                WHEN nv.ChucVu IN ('LT', 'TT') THEN
                    COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                              FROM PHANCONG_LAITAU pc 
                              INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                              WHERE pc.MaNV = nv.MaNV 
                              AND pc.TrangThai = N'Thay thế'
                              AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                              AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                    COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                              FROM PHANCONG_TOA pc 
                              INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                              WHERE pc.MaNV = nv.MaNV 
                              AND pc.TrangThai = N'Thay thế'
                              AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                              AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0)
                ELSE 0
            END as SoChuyenThayThe,
            
            -- Số CHUYẾN nghỉ phép - FIX + Filter theo tháng/năm
            CASE 
                WHEN nv.ChucVu IN ('LT', 'TT') THEN
                    COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                              FROM PHANCONG_LAITAU pc 
                              INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                              WHERE pc.MaNV = nv.MaNV 
                              AND pc.TrangThai = N'Nghỉ phép'
                              AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                              AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                    COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                              FROM PHANCONG_TOA pc 
                              INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                              WHERE pc.MaNV = nv.MaNV 
                              AND pc.TrangThai = N'Nghỉ phép'
                              AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                              AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0)
                ELSE 0
            END as SoChuyenNghiPhep,
            
            -- Tính tổng lương - FIX + Filter theo tháng/năm
            CASE 
                WHEN nv.ChucVu IN ('LT', 'TT') THEN
                    ISNULL(csl.LuongCoBan, 0) + ISNULL(csl.PhuCap, 0) +
                    (ISNULL(csl.ThuLaoChuyen, 0) * 
                        (COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                                   FROM PHANCONG_LAITAU pc 
                                   INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                                   WHERE pc.MaNV = nv.MaNV 
                                   AND pc.TrangThai = N'Thực hiện'
                                   AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                                   AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                         COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                                   FROM PHANCONG_TOA pc 
                                   INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                                   WHERE pc.MaNV = nv.MaNV 
                                   AND pc.TrangThai = N'Thực hiện'
                                   AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                                   AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0))
                    ) +
                    (ISNULL(csl.ThuLaoThayThe, 0) * 
                        (COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                                   FROM PHANCONG_LAITAU pc 
                                   INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                                   WHERE pc.MaNV = nv.MaNV 
                                   AND pc.TrangThai = N'Thay thế'
                                   AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                                   AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                         COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                                   FROM PHANCONG_TOA pc 
                                   INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                                   WHERE pc.MaNV = nv.MaNV 
                                   AND pc.TrangThai = N'Thay thế'
                                   AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                                   AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0))
                    ) -
                    (ISNULL(csl.PhatNghiPhep, 0) * 
                        (COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                                   FROM PHANCONG_LAITAU pc 
                                   INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                                   WHERE pc.MaNV = nv.MaNV 
                                   AND pc.TrangThai = N'Nghỉ phép'
                                   AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                                   AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                         COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                                   FROM PHANCONG_TOA pc 
                                   INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                                   WHERE pc.MaNV = nv.MaNV 
                                   AND pc.TrangThai = N'Nghỉ phép'
                                   AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                                   AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0))
                    )
                ELSE
                    ISNULL(csl.LuongCoBan, 0) + ISNULL(csl.PhuCap, 0)
            END as TongLuong
            
        FROM NHAN_VIEN nv
        INNER JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
        LEFT JOIN CHINH_SACH_LUONG csl ON csl.MaLoaiNV = nv.ChucVu
        WHERE 
            (@LoaiNV IS NULL OR nv.ChucVu = @LoaiNV)
            AND (@TimKiem IS NULL OR 
                 nv.MaNV LIKE '%' + @TimKiem + '%' OR 
                 nd.HoTen LIKE '%' + @TimKiem + '%' OR
                 nd.SDT LIKE '%' + @TimKiem + '%')
    )
    
    SELECT * FROM NhanVienData
    ORDER BY 
        CASE WHEN @SortBy = 'TongLuong' AND @SortOrder = 'DESC' THEN TongLuong END DESC,
        CASE WHEN @SortBy = 'TongLuong' AND @SortOrder = 'ASC' THEN TongLuong END ASC,
        CASE WHEN @SortBy = 'HoTen' AND @SortOrder = 'ASC' THEN HoTen END ASC,
        CASE WHEN @SortBy = 'HoTen' AND @SortOrder = 'DESC' THEN HoTen END DESC,
        CASE WHEN @SortBy = 'MaNV' AND @SortOrder = 'ASC' THEN MaNV END ASC,
        CASE WHEN @SortBy = 'MaNV' AND @SortOrder = 'DESC' THEN MaNV END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
    
    -- Tổng số bản ghi
    SELECT COUNT(*) AS TotalRecords
    FROM NHAN_VIEN nv
    INNER JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
    WHERE 
        (@LoaiNV IS NULL OR nv.ChucVu = @LoaiNV)
        AND (@TimKiem IS NULL OR 
             nv.MaNV LIKE '%' + @TimKiem + '%' OR 
             nd.HoTen LIKE '%' + @TimKiem + '%' OR
             nd.SDT LIKE '%' + @TimKiem + '%');

    RETURN 0;
END
GO

/* =============================================
   PROCEDURE 2: sp_LayThongTinLuongNhanVien
   FIX: Đổi điều kiện ChucVu
   ============================================= */
CREATE OR ALTER PROC sp_LayThongTinLuongNhanVien
    @MaNV NVARCHAR(50),
    @Thang INT = NULL,
    @Nam INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        nv.MaNV,
        nd.HoTen,
        nd.SDT,
        nv.GioiTinh,
        nv.ChucVu,
        nv.ChucVu as MaLoaiNV,
        
        -- Mapping tên hiển thị
        CASE 
            WHEN nv.ChucVu = 'LT' THEN N'Lái tàu'
            WHEN nv.ChucVu = 'TT' THEN N'Toa tàu'
            WHEN nv.ChucVu = 'AD' THEN N'Quản trị viên'
            WHEN nv.ChucVu = 'QL' THEN N'Quản lý'
            WHEN nv.ChucVu = 'BV' THEN N'Bán vé'
            ELSE nv.ChucVu
        END as TenLoaiNV,
        
        ISNULL(csl.LuongCoBan, 0) as LuongCoBan,
        ISNULL(csl.PhuCap, 0) as PhuCap,
        ISNULL(csl.ThuLaoChuyen, 0) as ThuLaoChuyen,
        ISNULL(csl.ThuLaoThayThe, 0) as ThuLaoThayThe,
        ISNULL(csl.PhatNghiPhep, 0) as PhatNghiPhep,
        
        -- Số CHUYẾN đã làm - FIX + Filter theo tháng/năm
        CASE 
            WHEN nv.ChucVu IN ('LT', 'TT') THEN
                COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                          FROM PHANCONG_LAITAU pc 
                          INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                          WHERE pc.MaNV = nv.MaNV 
                          AND pc.TrangThai = N'Thực hiện'
                          AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                          AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                          FROM PHANCONG_TOA pc 
                          INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                          WHERE pc.MaNV = nv.MaNV 
                          AND pc.TrangThai = N'Thực hiện'
                          AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                          AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0)
            ELSE 0
        END as SoChuyenDaLam,
        
        -- Số CHUYẾN thay thế - FIX + Filter theo tháng/năm
        CASE 
            WHEN nv.ChucVu IN ('LT', 'TT') THEN
                COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                          FROM PHANCONG_LAITAU pc 
                          INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                          WHERE pc.MaNV = nv.MaNV 
                          AND pc.TrangThai = N'Thay thế'
                          AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                          AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                          FROM PHANCONG_TOA pc 
                          INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                          WHERE pc.MaNV = nv.MaNV 
                          AND pc.TrangThai = N'Thay thế'
                          AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                          AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0)
            ELSE 0
        END as SoChuyenThayThe,
        
        -- Số CHUYẾN nghỉ phép - FIX + Filter theo tháng/năm
        CASE 
            WHEN nv.ChucVu IN ('LT', 'TT') THEN
                COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                          FROM PHANCONG_LAITAU pc 
                          INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                          WHERE pc.MaNV = nv.MaNV 
                          AND pc.TrangThai = N'Nghỉ phép'
                          AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                          AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                          FROM PHANCONG_TOA pc 
                          INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                          WHERE pc.MaNV = nv.MaNV 
                          AND pc.TrangThai = N'Nghỉ phép'
                          AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                          AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0)
            ELSE 0
        END as SoChuyenNghiPhep,
        
        -- Tính tổng lương - FIX + Filter theo tháng/năm
        CASE 
            WHEN nv.ChucVu IN ('LT', 'TT') THEN
                ISNULL(csl.LuongCoBan, 0) + ISNULL(csl.PhuCap, 0) +
                (ISNULL(csl.ThuLaoChuyen, 0) * 
                    (COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                               FROM PHANCONG_LAITAU pc 
                               INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                               WHERE pc.MaNV = nv.MaNV 
                               AND pc.TrangThai = N'Thực hiện'
                               AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                               AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                     COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                               FROM PHANCONG_TOA pc 
                               INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                               WHERE pc.MaNV = nv.MaNV 
                               AND pc.TrangThai = N'Thực hiện'
                               AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                               AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0))
                ) +
                (ISNULL(csl.ThuLaoThayThe, 0) * 
                    (COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                               FROM PHANCONG_LAITAU pc 
                               INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                               WHERE pc.MaNV = nv.MaNV 
                               AND pc.TrangThai = N'Thay thế'
                               AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                               AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                     COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                               FROM PHANCONG_TOA pc 
                               INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                               WHERE pc.MaNV = nv.MaNV 
                               AND pc.TrangThai = N'Thay thế'
                               AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                               AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0))
                ) -
                (ISNULL(csl.PhatNghiPhep, 0) * 
                    (COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                               FROM PHANCONG_LAITAU pc 
                               INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                               WHERE pc.MaNV = nv.MaNV 
                               AND pc.TrangThai = N'Nghỉ phép'
                               AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                               AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0) + 
                     COALESCE((SELECT COUNT(DISTINCT pc.MaChuyenTau) 
                               FROM PHANCONG_TOA pc 
                               INNER JOIN CHUYEN_TAU ct ON pc.MaChuyenTau = ct.MaChuyenTau
                               WHERE pc.MaNV = nv.MaNV 
                               AND pc.TrangThai = N'Nghỉ phép'
                               AND (@Thang IS NULL OR MONTH(ct.ThoiGianXuatPhat) = @Thang)
                               AND (@Nam IS NULL OR YEAR(ct.ThoiGianXuatPhat) = @Nam)), 0))
                )
            ELSE
                ISNULL(csl.LuongCoBan, 0) + ISNULL(csl.PhuCap, 0)
        END as TongLuong

    FROM NHAN_VIEN nv
    INNER JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
    LEFT JOIN CHINH_SACH_LUONG csl ON csl.MaLoaiNV = nv.ChucVu
    WHERE nv.MaNV = @MaNV;
END
GO