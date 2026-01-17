-- Fix stored procedure sp_GetDanhSachDoanTau
-- Chạy script này để cập nhật stored procedure

USE VNRAILWAY;
GO

-- Chạy lại stored procedure đã sửa
:r .\storedprocedure\sp_GetDanhSachDoanTau.sql
GO

-- Test với tất cả loại tàu (NULL)
DECLARE @SoKetQua INT, @ThongBao NVARCHAR(255);

EXEC sp_GetDanhSachDoanTau
    @LoaiTau = NULL,
    @TimKiem = NULL,
    @Trang = 1,
    @KichThuocTrang = 10,
    @SoKetQua = @SoKetQua OUTPUT,
    @ThongBao = @ThongBao OUTPUT;

SELECT @SoKetQua AS N'Tổng số đoàn tàu', @ThongBao AS N'Thông báo';
GO
