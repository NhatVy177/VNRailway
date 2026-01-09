package com.group10.vnrailway.dto;

/**
 * BookingTicket - DTO đại diện cho 1 vé trong đơn đặt vé
 * Khớp với JSON structure từ stored procedure usp_TaoDonDatVe_Online
 */
public class BookingTicket {
    
    // ========================================
    // THÔNG TIN GHẾ/GIƯỜNG (từ trip-detail)
    // ========================================
    private String maToa;       // Mã toa tàu
    private String maCho;       // Mã ghế/giường
    private String maThamSo;    // Mã tham số giá vé (GV001-GV012, hoặc đối tượng TS009-TS011)
    
    // ========================================
    // THÔNG TIN HÀNH KHÁCH (user nhập)
    // ========================================
    private String hoTen;       // BẮT BUỘC
    private String cmnd;        // BẮT BUỘC (CMND/CCCD)
    
    // OPTIONAL - có thể NULL
    private String sdt;         // Số điện thoại (optional)
    private String ngSinh;      // Ngày sinh (format: yyyy-MM-dd, optional)
    private String diaChi;      // Địa chỉ (optional)

    // ========================================
    // CONSTRUCTORS
    // ========================================
    public BookingTicket() {
    }

    public BookingTicket(String maToa, String maCho, String maThamSo, 
                        String hoTen, String cmnd) {
        this.maToa = maToa;
        this.maCho = maCho;
        this.maThamSo = maThamSo;
        this.hoTen = hoTen;
        this.cmnd = cmnd;
    }

    // ========================================
    // GETTERS & SETTERS
    // ========================================
    
    public String getMaToa() {
        return maToa;
    }

    public void setMaToa(String maToa) {
        this.maToa = maToa;
    }

    public String getMaCho() {
        return maCho;
    }

    public void setMaCho(String maCho) {
        this.maCho = maCho;
    }

    public String getMaThamSo() {
        return maThamSo;
    }

    public void setMaThamSo(String maThamSo) {
        this.maThamSo = maThamSo;
    }

    public String getHoTen() {
        return hoTen;
    }

    public void setHoTen(String hoTen) {
        this.hoTen = hoTen;
    }

    public String getCmnd() {
        return cmnd;
    }

    public void setCmnd(String cmnd) {
        this.cmnd = cmnd;
    }

    public String getSdt() {
        return sdt;
    }

    public void setSdt(String sdt) {
        this.sdt = sdt;
    }

    public String getNgSinh() {
        return ngSinh;
    }

    public void setNgSinh(String ngSinh) {
        this.ngSinh = ngSinh;
    }

    public String getDiaChi() {
        return diaChi;
    }

    public void setDiaChi(String diaChi) {
        this.diaChi = diaChi;
    }

    // ========================================
    // UTILITY METHODS
    // ========================================
    
    @Override
    public String toString() {
        return "BookingTicket{" +
                "maToa='" + maToa + '\'' +
                ", maCho='" + maCho + '\'' +
                ", maThamSo='" + maThamSo + '\'' +
                ", hoTen='" + hoTen + '\'' +
                ", cmnd='" + cmnd + '\'' +
                ", sdt='" + sdt + '\'' +
                ", ngSinh='" + ngSinh + '\'' +
                ", diaChi='" + diaChi + '\'' +
                '}';
    }
}