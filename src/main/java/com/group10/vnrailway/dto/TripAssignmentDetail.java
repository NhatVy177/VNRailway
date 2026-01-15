package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO chi tiết chuyến tàu phân công
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TripAssignmentDetail {

    private String maChuyenTau;
    private String maTuyen;
    private String tenTuyen;
    private String maDoanTau;
    private String tenTau;
    private String loaiTau;
    
    private LocalDateTime thoiGianXuatPhat;
    private LocalDateTime thoiGianDuKienDen;
    private LocalDateTime thoiGianMoBanVe;
    private LocalDateTime thoiGianDongBanVe;
    
    private Integer soVeDaBan;
    private Long doanhThu;
    
    private Boolean laChuyenTuongLai;
}
