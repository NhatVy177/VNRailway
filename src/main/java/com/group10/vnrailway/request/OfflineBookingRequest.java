package com.group10.vnrailway.request;

import com.group10.vnrailway.dto.BookingTicket;
import java.util.List;

/**
 * Request DTO cho đặt vé offline bởi nhân viên bán vé
 * Khác với BookingRequest ở chỗ cần thông tin người đặt vé
 */
public class OfflineBookingRequest {

    private String maChuyenTau;
    private String maGaDi;
    private String maGaDen;
    private String phuongThucTT;
    
    // Thông tin người đặt vé (không phải user đang đăng nhập)
    private String nguoiDatHoTen;
    private String nguoiDatCMND;
    
    private List<BookingTicket> danhSachVe;

    // Getters and Setters
    public String getMaChuyenTau() {
        return maChuyenTau;
    }

    public void setMaChuyenTau(String maChuyenTau) {
        this.maChuyenTau = maChuyenTau;
    }

    public String getMaGaDi() {
        return maGaDi;
    }

    public void setMaGaDi(String maGaDi) {
        this.maGaDi = maGaDi;
    }

    public String getMaGaDen() {
        return maGaDen;
    }

    public void setMaGaDen(String maGaDen) {
        this.maGaDen = maGaDen;
    }

    public String getPhuongThucTT() {
        return phuongThucTT;
    }

    public void setPhuongThucTT(String phuongThucTT) {
        this.phuongThucTT = phuongThucTT;
    }

    public String getNguoiDatHoTen() {
        return nguoiDatHoTen;
    }

    public void setNguoiDatHoTen(String nguoiDatHoTen) {
        this.nguoiDatHoTen = nguoiDatHoTen;
    }

    public String getNguoiDatCMND() {
        return nguoiDatCMND;
    }

    public void setNguoiDatCMND(String nguoiDatCMND) {
        this.nguoiDatCMND = nguoiDatCMND;
    }

    public List<BookingTicket> getDanhSachVe() {
        return danhSachVe;
    }

    public void setDanhSachVe(List<BookingTicket> danhSachVe) {
        this.danhSachVe = danhSachVe;
    }
}
