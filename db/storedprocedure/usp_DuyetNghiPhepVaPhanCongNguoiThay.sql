USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_DuyetNghiPhepVaPhanCongNguoiThay
-- HOTFIX: ChucVu + kiểm tra trùng lịch
-- =============================================
CREATE OR ALTER PROC usp_DuyetNghiPhepVaPhanCongNguoiThay
    @MaChuyenTau NCHAR(10),
    @MaNhanVienNghiPhep NCHAR(10),
    @MaNhanVienThayThe NCHAR(10),
    @MaNVQL NCHAR(10),
    @ThongBao NVARCHAR(200) OUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO PHANCONG_LAITAU (MaNV, MaChuyenTau, TrangThai, MaNVQL)
    VALUES (@MaNhanVienThayThe, @MaChuyenTau, N'Thay thế', @MaNVQL);

    SET @ThongBao = N'Duyệt nghỉ phép & phân công thay thế thành công.';
    RETURN 0;
END
GO
