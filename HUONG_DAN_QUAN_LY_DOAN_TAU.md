# HƯỚNG DẪN SỬ DỤNG CHỨC NĂNG QUẢN LÝ ĐOÀN TÀU

## Tổng quan
Chức năng quản lý đoàn tàu cho phép nhân viên quản lý:
- Xem danh sách tất cả đoàn tàu với thông tin chi tiết
- Thêm đoàn tàu mới
- Cập nhật thông tin đoàn tàu
- Xem lịch sử các chuyến tàu của đoàn tàu

## Các file đã tạo

### 1. Stored Procedures (db/storedprocedure/)
- `sp_GetDanhSachDoanTau.sql`: Lấy danh sách đoàn tàu với phân trang và filter
- `sp_ThemDoanTau.sql`: Thêm đoàn tàu mới
- `sp_CapNhatDoanTau.sql`: Cập nhật thông tin đoàn tàu
- `sp_GetLichSuChuyenTauDoanTau.sql`: Xem lịch sử chuyến tàu

### 2. DTO Classes (src/main/java/com/group10/vnrailway/dto/)
- `TrainList.java`: DTO cho danh sách đoàn tàu
- `TrainHistory.java`: DTO cho lịch sử chuyến tàu

### 3. Repository (src/main/java/com/group10/vnrailway/repository/)
- Cập nhật `TrainRepository.java` với các methods:
  - `getAllTrains()`: Lấy danh sách đoàn tàu
  - `createTrain()`: Thêm đoàn tàu
  - `updateTrain()`: Cập nhật đoàn tàu
  - `getTrainHistory()`: Lấy lịch sử chuyến tàu

### 4. Service (src/main/java/com/group10/vnrailway/service/)
- Cập nhật `TrainService.java` với business logic

### 5. Controller (src/main/java/com/group10/vnrailway/controller/manager/)
- Cập nhật `ManagerTrainController.java` với các endpoints:
  - `GET /manager/trains`: Danh sách đoàn tàu
  - `GET /manager/trains/create`: Form thêm mới
  - `POST /manager/trains/create`: Xử lý thêm mới
  - `GET /manager/trains/{id}/edit`: Form sửa
  - `POST /manager/trains/{id}/edit`: Xử lý cập nhật
  - `GET /manager/trains/{id}/history`: Lịch sử chuyến tàu

### 6. Views (src/main/resources/templates/pages/manager/train/)
- `train-list.html`: Trang danh sách đoàn tàu
- `train-form.html`: Form thêm/sửa đoàn tàu
- `train-history.html`: Trang lịch sử chuyến tàu

## Cách chạy

### Bước 1: Chạy SQL Scripts
Chạy các stored procedures trong SQL Server:
```sql
-- Chạy lần lượt các file:
-- db/storedprocedure/sp_GetDanhSachDoanTau.sql
-- db/storedprocedure/sp_ThemDoanTau.sql
-- db/storedprocedure/sp_CapNhatDoanTau.sql
-- db/storedprocedure/sp_GetLichSuChuyenTauDoanTau.sql
```

### Bước 2: Build và chạy ứng dụng
```bash
./mvnw clean install
./mvnw spring-boot:run
```

### Bước 3: Truy cập
1. Đăng nhập với tài khoản MANAGER
2. Truy cập: `http://localhost:8080/manager/trains`

## Tính năng

### 1. Danh sách đoàn tàu
- Hiển thị tất cả đoàn tàu với thông tin:
  - Mã đoàn tàu, tên tàu, hãng sản xuất
  - Ngày vận hành, loại tàu (Nhanh/Thường)
  - Số toa tàu
  - Km đã chạy trong tuần / Km tối đa
  - Trạng thái hoạt động (Bình thường/Dưới mức/Vượt mức)
  - Số chuyến trong tuần
  
- Bộ lọc:
  - Lọc theo loại tàu (Tàu nhanh/Tàu thường)
  - Tìm kiếm theo mã, tên, hãng sản xuất
  
- Phân trang: 10 đoàn tàu/trang

### 2. Thêm đoàn tàu mới
- Form nhập thông tin:
  - Mã đoàn tàu (4 ký tự, bắt buộc)
  - Tên tàu (tối đa 50 ký tự)
  - Hãng sản xuất
  - Ngày vận hành
  - Loại tàu (S: Tàu nhanh, T: Tàu thường)
  
- Validation:
  - Mã đoàn tàu không được trùng
  - Loại tàu chỉ nhận S hoặc T
  - Ngày vận hành không được trong tương lai

### 3. Cập nhật đoàn tàu
- Chỉnh sửa thông tin: tên tàu, hãng SX, ngày vận hành, loại tàu
- Mã đoàn tàu không thể thay đổi

### 4. Lịch sử chuyến tàu
- Xem lịch sử các chuyến tàu của đoàn tàu:
  - Mã chuyến, thời gian xuất phát
  - Tuyến đường, ga đi - ga đến
  - Khoảng cách
  - Trạng thái chuyến (Đã hoàn thành/Đang chạy/Đã hủy)
  - Số vé bán, số lái tàu, số nhân viên phục vụ
  
- Bộ lọc theo khoảng thời gian
- Mặc định hiển thị 3 tháng gần nhất
- Phân trang: 10 chuyến/trang

## Lưu ý
- Chức năng chỉ dành cho tài khoản có role MANAGER
- Dữ liệu km trong tuần được tính dựa trên function `fn_TinhTongKmDoanTauTrongTuan`
- Trạng thái hoạt động dựa trên tham số TS014 (km tối thiểu) và TS015 (km tối đa)

## Hỗ trợ
Nếu gặp vấn đề, kiểm tra:
1. Các stored procedures đã được tạo đúng chưa
2. Ứng dụng đã kết nối database thành công chưa
3. Tài khoản đăng nhập có role MANAGER chưa
