package com.group10.vnrailway.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * TicketChangeDTO - Thông tin vé để đổi
 */
@Data
public class TicketChangeDTO {
    private String maVe;
    private String maDon;
    private String maKH;
    private String tenKhachHang;
    private String sdt;
    private String maGhe;
    private String loaiCho;
    private String soGhe;
    private String maToa;
    private String tenToa;
    private String maChuyenTau;
    private String maGaDi;
    private String maGaDen;
    private LocalDateTime thoiGianXuatPhat;
    private LocalDateTime thoiGianDen;
    private String tenTuyen;
    private String doiTuong;
    private BigDecimal giaVeCu;
    private String trangThai;
    private BigDecimal phiDoiVe;
    private Integer thoiGianConLai; // Phút
    private Integer thoiGianToiThieuDoiVe; // Phút
    private Boolean duocDoiVe;
    private String lyDoKhongDoiDuoc;
}
