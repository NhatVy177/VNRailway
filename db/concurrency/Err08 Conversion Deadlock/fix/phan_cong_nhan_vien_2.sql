USE VNRAILWAY
GO
DECLARE @ThongBao NVARCHAR(200);
DECLARE @Ret INT;

PRINT N'T2: Bắt đầu...';
EXEC @Ret = usp_PhanCongToaTau_FIXED
    @MaChuyenTau = 'VNW5B64972',
    @VaiTro = N'Nhân viên',
    @MaToa = 'T0098',
    @MaNhanVien = 'U010234', -- Thay người khác nữa
    @MaNVQL = 'U010010',
    @ThongBao = @ThongBao OUT;

PRINT N'T2 Kết quả: ' + @ThongBao;