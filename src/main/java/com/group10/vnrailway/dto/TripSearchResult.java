package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO cho kết quả tra cứu chuyến tàu
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TripSearchResult {

    private String maChuyenTau;
    private String maTuyen;
    private String tenTuyen;
    private String maDoanTau;
    private String tenTau;
    private String loaiTau;  // S = Se, T = Thường

    // Thông tin ga đi
    private String maGaDi;
    private String tenGaDi;
    private Integer trinhTuGaDi;

    // Thông tin ga đến
    private String maGaDen;
    private String tenGaDen;
    private Integer trinhTuGaDen;

    // Thời gian
    private LocalDateTime thoiGianXuatPhat;
    private LocalDateTime thoiGianDuKienDen;
    private LocalDateTime thoiGianKhoiHanh;
    private LocalDateTime thoiGianDenDuKien;

    // Khoảng cách và số chỗ
    private Double khoangCach;
    private Integer soChoTrong;
}
