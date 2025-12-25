USE VNRAILWAY
GO

DELETE HE_SO_VE
GO

INSERT INTO HE_SO_VE (MaHeSo, NgayBD, NgayKT, HeSo, GhiChu) VALUES ('HSV01', '2024-12-29', '2025-01-03', 1.1, N'Tết Tây (tăng giá): Tăng giá 10% do nhu cầu cao trong dịp lễ quốc tế.');
INSERT INTO HE_SO_VE (MaHeSo, NgayBD, NgayKT, HeSo, GhiChu) VALUES ('HSV02', '2025-01-13', '2025-01-29', 1.2, N'Trước Tết Nguyên Đán (tăng giá): Tăng giá 20% vì nhu cầu đi lại tăng cao trong thời gian chuẩn bị Tết.');
INSERT INTO HE_SO_VE (MaHeSo, NgayBD, NgayKT, HeSo, GhiChu) VALUES ('HSV03', '2025-01-30', '2025-02-12', 0.8, N'Trong Tết Nguyên Đán (giảm giá): Giảm giá 20% để thu hút khách hàng trong dịp lễ Tết, khuyến khích di chuyển trong thời gian nghỉ Tết.');
INSERT INTO HE_SO_VE (MaHeSo, NgayBD, NgayKT, HeSo, GhiChu) VALUES ('HSV04', '2025-02-13', '2025-02-23', 1.1, N'Sau Tết Nguyên Đán (tăng giá): Tăng giá 10% do nhu cầu đi lại phục hồi sau kỳ nghỉ Tết.');
INSERT INTO HE_SO_VE (MaHeSo, NgayBD, NgayKT, HeSo, GhiChu) VALUES ('HSV05', '2025-04-28', '2025-05-03', 1.15, N'30/4 và 1/5 (tăng giá): Tăng giá 15% do kỳ nghỉ lễ lớn, nhu cầu di chuyển tăng cao.');
INSERT INTO HE_SO_VE (MaHeSo, NgayBD, NgayKT, HeSo, GhiChu) VALUES ('HSV06', '2025-06-01', '2025-08-31', 0.95, N'Mùa hè (giảm giá): Khuyến khích di chuyển bằng tàu do mùa du lịch cao điểm, nhu cầu sử dụng dịch vụ vận chuyển tăng cao.');
INSERT INTO HE_SO_VE (MaHeSo, NgayBD, NgayKT, HeSo, GhiChu) VALUES ('HSV07', '2025-08-29', '2025-09-03', 1.1, N'2/9 (tăng giá): Tăng giá 10% vì nhu cầu đi lại cao trong dịp lễ Quốc khánh, kỳ nghỉ dài.');
GO

select * from HE_SO_VE