package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO cho thông tin phân công hiện tại
 * Dùng để hiển thị bảng phân công trong trip-detail
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssignmentInfo {
    
    private Integer stt;
    private String vaiTro;
    private String maNV;
    private String tenNhanVien;
    private String trangThai;
    private String thoiGianLamViec;
    private String maToa;
    private String loaiPhanCong; // 'LAITAU' hoặc 'TOATAU'
    
    /**
     * Helper method: Kiểm tra đã phân công chưa
     */
    public boolean getDaPhanCong() {
        return maNV != null && !maNV.trim().isEmpty();
    }
    
    /**
     * Alias for Thymeleaf (supports both isDaPhanCong and getDaPhanCong)
     */
    public boolean isDaPhanCong() {
        return getDaPhanCong();
    }
    
    /**
     * Helper method: Kiểm tra là phân công lái tàu
     */
    public boolean getLaiTau() {
        return "LAITAU".equals(loaiPhanCong);
    }
    
    /**
     * Alias for Thymeleaf
     */
    public boolean isLaiTau() {
        return getLaiTau();
    }
    
    /**
     * Helper method: Kiểm tra là phân công toa tàu
     */
    public boolean getToaTau() {
        return "TOATAU".equals(loaiPhanCong);
    }
    
    /**
     * Alias for Thymeleaf
     */
    public boolean isToaTau() {
        return getToaTau();
    }
    
    /**
     * Helper method: Hiển thị tên nhân viên
     */
    public String getDisplayName() {
        if (getDaPhanCong()) {
            return maNV.trim() + " - " + tenNhanVien;
        }
        return "-- Chưa phân công --";
    }
    
    /**
     * Helper method: Kiểm tra trạng thái nghỉ phép
     */
    public boolean getNghiPhep() {
        return "Nghỉ phép".equals(trangThai);
    }
    
    /**
     * Alias for Thymeleaf
     */
    public boolean isNghiPhep() {
        return getNghiPhep();
    }
    
    /**
     * Helper method: Kiểm tra trạng thái thay thế
     */
    public boolean getThayThe() {
        return "Thay thế".equals(trangThai);
    }
    
    /**
     * Alias for Thymeleaf
     */
    public boolean isThayThe() {
        return getThayThe();
    }
    
    /**
     * Helper method: CSS class cho trạng thái
     */
    public String getStatusClass() {
        if (isNghiPhep()) {
            return "status-leave";
        } else if (isThayThe()) {
            return "status-replacement";
        } else if (isDaPhanCong()) {
            return "status-assigned";
        }
        return "status-empty";
    }
}