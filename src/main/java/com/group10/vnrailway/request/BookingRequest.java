package com.group10.vnrailway.request;

import com.group10.vnrailway.dto.BookingTicket;
import java.util.List;

public class BookingRequest {

    private String maChuyenTau;
    private String maGaDi;
    private String maGaDen;
    private String maKHNguoiDat;
    private String phuongThucTT;

    private List<BookingTicket> danhSachVe;

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

    public String getMaKHNguoiDat() {
        return maKHNguoiDat;
    }
    public void setMaKHNguoiDat(String maKHNguoiDat) {
        this.maKHNguoiDat = maKHNguoiDat;
    }

    public String getPhuongThucTT() {
        return phuongThucTT;
    }
    public void setPhuongThucTT(String phuongThucTT) {
        this.phuongThucTT = phuongThucTT;
    }

    public List<BookingTicket> getDanhSachVe() {
        return danhSachVe;
    }
    public void setDanhSachVe(List<BookingTicket> danhSachVe) {
        this.danhSachVe = danhSachVe;
    }
}
