USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: sp_KiemTraDieuKienDoiVe
-- Kiểm tra vé có đủ điều kiện đổi không
-- =============================================
CREATE OR ALTER PROC sp_KiemTraDieuKienDoiVe
    @MaVe NVARCHAR(10),
    @KetQua BIT OUTPUT,
    @ThongBao NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TrangThai NVARCHAR(20);
    DECLARE @MaChuyenTau NVARCHAR(10);
    DECLARE @ThoiGianXuatPhat DATETIME;
    DECLARE @ThoiGianToiThieuDoiVe INT; -- Phút
    DECLARE @ThoiGianConLai INT;
    
    -- Lấy tham số thời gian đổi vé (TS008)
    SELECT @ThoiGianToiThieuDoiVe = GiaTriThamSo
    FROM THAM_SO
    WHERE MaThamSo = 'TS008';
    
    -- Kiểm tra vé tồn tại
    IF NOT EXISTS (SELECT 1 FROM CHI_TIET_VE WHERE MaVe = @MaVe)
    BEGIN
        SET @KetQua = 0;
        SET @ThongBao = N'Vé không tồn tại trong hệ thống';
        RETURN 1;
    END
    
    -- Lấy thông tin vé
    SELECT 
        @TrangThai = ctv.TrangThai,
        @MaChuyenTau = ddv.MaChuyenTau,
        @ThoiGianXuatPhat = ct.ThoiGianXuatPhat
    FROM CHI_TIET_VE ctv
    JOIN DON_DAT_VE ddv ON ctv.MaDon = ddv.MaDon
    JOIN CHUYEN_TAU ct ON ddv.MaChuyenTau = ct.MaChuyenTau
    WHERE ctv.MaVe = @MaVe;
    
    -- Kiểm tra trạng thái vé
    IF @TrangThai != N'Đã thanh toán'
    BEGIN
        SET @KetQua = 0;
        SET @ThongBao = N'Vé chưa được thanh toán hoặc đã bị hủy';
        RETURN 2;
    END
    
    -- Kiểm tra thời gian đổi vé
    SET @ThoiGianConLai = DATEDIFF(MINUTE, GETDATE(), @ThoiGianXuatPhat);
    
    IF @ThoiGianConLai < @ThoiGianToiThieuDoiVe
    BEGIN
        SET @KetQua = 0;
        SET @ThongBao = N'Không thể đổi vé do đã quá thời gian cho phép (phải đổi trước ' 
                        + CAST(@ThoiGianToiThieuDoiVe AS NVARCHAR(10)) + N' phút)';
        RETURN 3;
    END
    
    -- Kiểm tra chuyến tàu đã khởi hành chưa
    IF @ThoiGianXuatPhat <= GETDATE()
    BEGIN
        SET @KetQua = 0;
        SET @ThongBao = N'Không thể đổi vé do chuyến tàu đã khởi hành';
        RETURN 4;
    END
    
    -- Vé hợp lệ để đổi
    SET @KetQua = 1;
    SET @ThongBao = N'Vé hợp lệ để đổi';
    RETURN 0;
END
GO
