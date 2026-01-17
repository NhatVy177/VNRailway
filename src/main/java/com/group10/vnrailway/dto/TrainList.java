package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * DTO cho danh sách đoàn tàu với thông tin chi tiết
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TrainList {
    private String maDoanTau;
    private String tenTau;
    private String hangSX;
    private LocalDate ngVanHanh;
    private Integer soNamHoatDong;
    private String loaiTau;
    private String tenLoaiTau;
    private Integer soToaTau;
    private BigDecimal kmTrongTuan;
    private BigDecimal kmToiThieu;
    private BigDecimal kmToiDa;
    private String trangThaiKm;
    private String moTaTrangThai;
    private Integer soChuyenTrongTuan;
    private String cacTuyenDangPhucVu;
}
