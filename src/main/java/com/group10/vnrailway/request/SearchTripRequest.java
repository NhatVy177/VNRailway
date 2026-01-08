package com.group10.vnrailway.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDate;
import java.time.LocalTime;

/**
 * Request object cho form tìm kiếm chuyến tàu
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SearchTripRequest {

    private String maGaDi;      // Mã ga đi
    private String maGaDen;     // Mã ga đến
    
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    private LocalDate ngayDi;   // Ngày đi
    
    @DateTimeFormat(pattern = "HH:mm")
    private LocalTime gioKhoiHanhTu;    // Giờ khởi hành từ
    
    @DateTimeFormat(pattern = "HH:mm")
    private LocalTime gioKhoiHanhDen;   // Giờ khởi hành đến
    
    private String loaiTau;     // 'S' = SE, 'T' = Thường, null = Tất cả
    private String loaiCho;     // 'GH', 'GI4', 'GI6', null = Tất cả
    private String trangThai;   // 'C' = Còn chỗ, null = Tất cả
    
    // Pagination parameters
    private Integer page = 1;        // Trang hiện tại (mặc định = 1)
    private Integer size = 7;        // Số kết quả mỗi trang (mặc định = 7)
    
    // Helper methods
    public int getPage() {
        return page != null && page > 0 ? page : 1;
    }
    
    public int getSize() {
        return size != null && size > 0 ? size : 7;
    }
    
    public int getOffset() {
        return (getPage() - 1) * getSize();
    }
}