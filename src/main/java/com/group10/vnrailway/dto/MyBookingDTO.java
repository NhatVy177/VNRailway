package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * MyBookingDTO - DTO chứa thông tin đơn đặt vé và các vé trong đơn
 * Dùng để hiển thị danh sách vé đã đặt của khách hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MyBookingDTO {
    
    // Thông tin đơn đặt vé
    private String maDon;
    private LocalDateTime thoiGianDatVe;
    private BigDecimal tongTien;
    private String trangThaiThanhToan;
    
    // Thông tin chuyến tàu
    private String maChuyenTau;
    private String tenTau;
    private LocalDateTime thoiGianKhoiHanh;
    
    // Thông tin ga
    private String maGaDi;
    private String tenGaDi;
    private String maGaDen;
    private String tenGaDen;
    
    // Thông tin vé
    private String maVe;
    private String maToa;
    private String maCho;
    private String loaiCho;
    private String tenHanhKhach;
    private String cmnd;
    private BigDecimal giaVe;
    private String trangThaiVe;
    
    // Thông tin người đặt (dùng khi nhân viên tra cứu)
    private String nguoiDatHoTen;
    private String nguoiDatSDT;
    private String nguoiDatCMND;
}
