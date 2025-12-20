USE VNRAILWAY
GO

DELETE THAM_SO
GO

INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV001', N'Ghế - Hạng sang', 450);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV002', N'Giường phòng 4 tầng 1 - Hạng sang', 700);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV003', N'Giường phòng 4 tầng 2 - Hạng sang', 650);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV004', N'Giường phòng 6 tầng 1 - Hạng sang', 670);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV005', N'Giường phòng 6 tầng 2 - Hạng sang', 620);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV006', N'Giường phòng 6 tầng 3 - Hạng sang', 570);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV007', N'Ghế - Hạng thường', 350);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV008', N'Giường phòng 4 tầng 1 - Hạng thường', 600);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV009', N'Giường phòng 4 tầng 2 - Hạng thường', 550);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV010', N'Giường phòng 6 tầng 1 - Hạng thường', 580);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV011', N'Giường phòng 6 tầng 2 - Hạng thường', 530);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('GV012', N'Giường phòng 6 tầng 3 - Hạng thường', 480);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS001', N'Số vé tối đa mỗi tài khoản được đặt cho 1 chuyến tàu (vé)', 6);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS002', N'Thời điểm mở bán vé trước thời điểm tàu xuất phát (ngày)', 30);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS003', N'Thời điểm đóng bán vé trước thời điểm tàu xuất phát (phút)', 60);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS004', N'Thời gian thanh toán online sau khi đặt vé online (phút)', 15);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS005', N'Thời gian thanh toán trực tiếp sau khi đặt vé online (phút)', 180);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS006', N'Thời điểm xuất vé trước thời điểm tàu xuất phát (phút)', 30);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS007', N'Tỷ lệ tiền phạt khi đổi vé (tính trên giá vé cũ) (%)', 5);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS008', N'Thời điểm đổi vé trước thời điểm tàu xuất phát (phút)', 240);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS009', N'Tỷ lệ giảm giá vé cho người già (%)', 0.15);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS010', N'Tỷ lệ giảm giá vé cho học sinh (%)', 0.12);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS011', N'Tỷ lệ giảm giá vé cho sinh viên (%)', 0.1);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS012', N'Thời điểm phân công trước thời điểm tàu xuất phát (giờ)', 24);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS013', N'Thời điểm duyệt nghỉ phép trước thời điểm tàu xuất phát (giờ)', 12);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS014', N'Tổng số km tối thiểu mỗi đoàn tàu chạy trong 1 tuần (km)', 500);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS015', N'Tổng số km tối đa mỗi đoàn tàu chạy trong 1 tuần (km)', 4000);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS016', N'Tổng thời gian chạy tàu tối thiểu của mỗi nhân viên lái tàu trong 1 tuần (giờ)', 10);
INSERT INTO THAM_SO (MaThamSo, TenThamSo, GiaTriThamSo) VALUES ('TS017', N'Tổng thời gian chạy tàu tối đa của mỗi nhân viên lái tàu trong 1 tuần (giờ)', 45);

GO

select * from THAM_SO

