USE VNRAILWAY
GO

-- =============================================
-- PROCEDURE: usp_CapNhatTrangThaiNghiPhepQuaHan
-- =============================================
CREATE OR ALTER PROC usp_CapNhatTrangThaiNghiPhepQuaHan
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @GioHanDuyet DECIMAL(12,2);

    SELECT @GioHanDuyet = GiaTriThamSo
    FROM THAM_SO
    WHERE MaThamSo = 'TS013';

    UPDATE pl
    SET TrangThai = N'Thực hiện'
    FROM PHANCONG_LAITAU pl
    JOIN CHUYEN_TAU ct ON pl.MaChuyenTau = ct.MaChuyenTau
    WHERE pl.TrangThai = N'Nghỉ phép'
      AND DATEADD(HOUR, @GioHanDuyet, GETDATE()) > ct.ThoiGianXuatPhat;

    UPDATE pt
    SET TrangThai = N'Thực hiện'
    FROM PHANCONG_TOA pt
    JOIN CHUYEN_TAU ct ON pt.MaChuyenTau = ct.MaChuyenTau
    WHERE pt.TrangThai = N'Nghỉ phép'
      AND DATEADD(HOUR, @GioHanDuyet, GETDATE()) > ct.ThoiGianXuatPhat;

    RETURN 0;
END
GO
