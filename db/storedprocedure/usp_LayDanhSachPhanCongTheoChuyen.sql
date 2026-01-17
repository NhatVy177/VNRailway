USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_LayDanhSachPhanCongTheoChuyen
-- FIXED: Sắp xếp chuẩn theo STT (Vị trí -> Trạng thái ưu tiên)
-- =============================================
CREATE OR ALTER PROC usp_LayDanhSachPhanCongTheoChuyen
    @MaChuyenTau NCHAR(10),
    @ThongBao NVARCHAR(255) OUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
    BEGIN
        SET @ThongBao = N'Chuyến tàu không tồn tại.';
        RETURN -1009;
    END

    -- Lấy MaDoanTau của chuyến
    DECLARE @MaDoanTau NCHAR(4);
    SELECT @MaDoanTau = MaDoanTau FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau;

    -- =============================================
    -- HIỂN THỊ DANH SÁCH & ĐÁNH SỐ THỨ TỰ
    -- =============================================
    SELECT 
        -- Đánh số thứ tự dựa trên logic sắp xếp ưu tiên
        ROW_NUMBER() OVER (
            ORDER BY 
                SortOrder, 
                SubOrder,
                -- Logic ưu tiên hiển thị trạng thái trong cùng 1 vị trí:
                -- 1. Thực hiện (Người làm chính)
                -- 2. Thay thế (Người làm thay)
                -- 3. Nghỉ phép (Để xem lịch sử/lý do)
                -- 4. NULL (Chưa phân công)
                CASE TrangThai
                    WHEN N'Thực hiện' THEN 1
                    WHEN N'Thay thế' THEN 2
                    WHEN N'Nghỉ phép' THEN 3
                    ELSE 4 
                END
        ) AS STT,
        VaiTro,
        MaNV,
        TenNhanVien,
        TrangThai,
        MaToa,
        LoaiPhanCong
    FROM (
        -- ... (Giữ nguyên phần UNION ALL lấy dữ liệu như cũ) ...
        
        -- 1. LÁI TÀU - Lái chính
        SELECT 
            1 AS SortOrder, 1 AS SubOrder, N'Lái chính' AS VaiTro,
            pclt.MaNV, nd.HoTen AS TenNhanVien, pclt.TrangThai,
            NULL AS MaToa, 'LAITAU' AS LoaiPhanCong
        FROM (SELECT 1 AS Placeholder) x
        LEFT JOIN PHANCONG_LAITAU pclt ON pclt.MaChuyenTau = @MaChuyenTau AND pclt.VaiTro = N'Lái chính'
        LEFT JOIN NHAN_VIEN nv ON pclt.MaNV = nv.MaNV
        LEFT JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung

        UNION ALL

        -- Lái tàu - Lái phụ
        SELECT 
            1 AS SortOrder, 2 AS SubOrder, N'Lái phụ' AS VaiTro,
            pclt.MaNV, nd.HoTen AS TenNhanVien, pclt.TrangThai,
            NULL AS MaToa, 'LAITAU' AS LoaiPhanCong
        FROM (SELECT 1 AS Placeholder) x
        LEFT JOIN PHANCONG_LAITAU pclt ON pclt.MaChuyenTau = @MaChuyenTau AND pclt.VaiTro = N'Lái phụ'
        LEFT JOIN NHAN_VIEN nv ON pclt.MaNV = nv.MaNV
        LEFT JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung

        UNION ALL

        -- 2. TRƯỞNG TOA
        SELECT 
            2 AS SortOrder, 1 AS SubOrder, N'Trưởng toa' AS VaiTro,
            pct.MaNV, nd.HoTen AS TenNhanVien, pct.TrangThai,
            tt.MaToa, 'TOATAU' AS LoaiPhanCong
        FROM (SELECT TOP 1 MaToa FROM TOA_TAU WHERE MaDoanTau = @MaDoanTau ORDER BY STT) tt
        LEFT JOIN PHANCONG_TOA pct ON pct.MaChuyenTau = @MaChuyenTau AND pct.VaiTro = N'Trưởng toa'
        LEFT JOIN NHAN_VIEN nv ON pct.MaNV = nv.MaNV
        LEFT JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung

        UNION ALL

        -- 3. NHÂN VIÊN TOA
        SELECT 
            3 AS SortOrder, tt.STT AS SubOrder, N'Nhân viên' AS VaiTro,
            pct.MaNV, nd.HoTen AS TenNhanVien, pct.TrangThai,
            tt.MaToa, 'TOATAU' AS LoaiPhanCong
        FROM TOA_TAU tt
        LEFT JOIN PHANCONG_TOA pct ON pct.MaChuyenTau = @MaChuyenTau 
            AND pct.MaToa = tt.MaToa AND pct.VaiTro = N'Nhân viên'
        LEFT JOIN NHAN_VIEN nv ON pct.MaNV = nv.MaNV
        LEFT JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
        WHERE tt.MaDoanTau = @MaDoanTau
    ) AS AllAssignments
    -- SẮP XẾP CUỐI CÙNG CHỈ CẦN THEO STT ĐÃ TÍNH Ở TRÊN
    ORDER BY STT;

    SET @ThongBao = N'Lấy danh sách phân công thành công.';
    RETURN 0;
END
GO