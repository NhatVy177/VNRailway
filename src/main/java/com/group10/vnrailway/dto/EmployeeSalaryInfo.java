package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeSalaryInfo {
    private String maNV;
    private String hoTen;
    private String sdt;
    private String gioiTinh;
    private String maLoaiNV;
    private String tenLoaiNV;
    
    // Thông tin lương
    private BigDecimal luongCoBan;
    private BigDecimal phuCap;
    private BigDecimal thuLaoChuyen;
    private BigDecimal thuLaoThayThe;
    private BigDecimal phatNghiPhep;
    
    // Số liệu tính toán
    private Integer soChuyenDaLam;
    private Integer soChuyenThayThe;
    private Integer soChuyenNghiPhep;
    
    // Tổng lương
    private BigDecimal tongLuong;
    
    public BigDecimal tinhTongLuong() {
        BigDecimal tong = BigDecimal.ZERO;
        
        // Lương cơ bản + phụ cấp
        if (luongCoBan != null) tong = tong.add(luongCoBan);
        if (phuCap != null) tong = tong.add(phuCap);
        
        // + Thù lao chuyến tàu
        if (thuLaoChuyen != null && soChuyenDaLam != null) {
            tong = tong.add(thuLaoChuyen.multiply(BigDecimal.valueOf(soChuyenDaLam)));
        }
        
        // + Thù lao thay thế
        if (thuLaoThayThe != null && soChuyenThayThe != null) {
            tong = tong.add(thuLaoThayThe.multiply(BigDecimal.valueOf(soChuyenThayThe)));
        }
        
        // - Phạt nghỉ phép
        if (phatNghiPhep != null && soChuyenNghiPhep != null) {
            tong = tong.subtract(phatNghiPhep.multiply(BigDecimal.valueOf(soChuyenNghiPhep)));
        }
        
        this.tongLuong = tong;
        return tong;
    }
}
