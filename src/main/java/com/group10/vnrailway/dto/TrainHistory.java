package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * DTO cho lịch sử chuyến tàu của đoàn tàu
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TrainHistory {
    private String maChuyenTau;
    private LocalDateTime thoiGianXuatPhat;
    private String maTuyen;
    private String tenTuyen;
    private BigDecimal khoangCach;
    private String gaDi;
    private String gaDen;
    private String trangThai;
    private String moTaTrangThai;
    private Integer soVeBan;
    private Integer soLaiTau;
    private Integer soNhanVienPhucVu;
}
