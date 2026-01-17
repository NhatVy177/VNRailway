CREATE OR ALTER PROC usp_LayThongKePhanCongTheoChuyen
    @MaChuyenTau NCHAR(10),
    @ThongBao NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra chuyến tàu tồn tại
    IF NOT EXISTS (SELECT 1 FROM CHUYEN_TAU WHERE MaChuyenTau = @MaChuyenTau)
    BEGIN
        SET @ThongBao = N'Chuyến tàu không tồn tại.';
        RETURN -1009;
    END

    DECLARE @TongViTri INT = 0;
    DECLARE @DaPhanCong INT = 0;
    DECLARE @SoNghiPhep INT = 0;

    -- 2. Tính TỔNG VỊ TRÍ cần thiết
    -- Công thức: 2 (Lái chính/phụ) + 1 (Trưởng toa) + Số lượng toa (1 NV/toa)
    SELECT @TongViTri = 3 + COUNT(*)
    FROM TOA_TAU tt
    JOIN CHUYEN_TAU ct ON tt.MaDoanTau = ct.MaDoanTau
    WHERE ct.MaChuyenTau = @MaChuyenTau;

    -- 3. Tính SỐ NGƯỜI ĐANG LÀM VIỆC (Đã phân công)
    -- Logic mới: Chỉ đếm trạng thái 'Thực hiện' hoặc 'Thay thế'
    SELECT @DaPhanCong = COUNT(DISTINCT MaNV)
    FROM (
        SELECT MaNV FROM PHANCONG_LAITAU 
        WHERE MaChuyenTau = @MaChuyenTau 
          AND TrangThai IN (N'Thực hiện', N'Thay thế') -- Chỉ lấy người đang làm

        UNION ALL
        
        SELECT MaNV FROM PHANCONG_TOA 
        WHERE MaChuyenTau = @MaChuyenTau 
          AND TrangThai IN (N'Thực hiện', N'Thay thế') -- Chỉ lấy người đang làm
    ) x;

    -- 4. Tính SỐ NGƯỜI NGHỈ PHÉP (Để tham khảo)
    SELECT @SoNghiPhep = COUNT(DISTINCT MaNV)
    FROM (
        SELECT MaNV FROM PHANCONG_LAITAU WHERE MaChuyenTau = @MaChuyenTau AND TrangThai = N'Nghỉ phép'
        UNION ALL
        SELECT MaNV FROM PHANCONG_TOA WHERE MaChuyenTau = @MaChuyenTau AND TrangThai = N'Nghỉ phép'
    ) y;

    -- 5. Trả về kết quả
    -- Số còn thiếu = Tổng vị trí - Số người đang thực sự làm việc
    SELECT
        @TongViTri AS TongSoViTri,
        @DaPhanCong AS SoNguoiDangLamViec, -- Tên cột rõ nghĩa hơn
        @SoNghiPhep AS SoNguoiNghiPhep,
        CASE 
            WHEN (@TongViTri - @DaPhanCong) < 0 THEN 0 -- Tránh số âm nếu thừa người (hiếm gặp)
            ELSE (@TongViTri - @DaPhanCong) 
        END AS SoViTriConThieu;

    SET @ThongBao = N'Lấy thống kê thành công.';
    RETURN 0;
END
GO