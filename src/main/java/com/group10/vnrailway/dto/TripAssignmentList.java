package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO cho danh sách chuyến tàu quản lý phân công
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TripAssignmentList {

    private String maChuyenTau;
    private String maTuyen;
    private String tenTuyen;
    private String maDoanTau;
    private String tenTau;
    private String loaiTau;
    
    private LocalDateTime thoiGianXuatPhat;
    private LocalDateTime thoiGianDuKienDen;
    
    private Integer tongSoViTri;
    private Integer soPhanCongDaCo;
    private Integer soNghiPhep;
    private Integer soConThieu;
    
    private String trangThaiPhanCong;
    private Boolean laChuyenTuongLai;
}
