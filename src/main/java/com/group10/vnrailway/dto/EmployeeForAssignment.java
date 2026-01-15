package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO cho nhân viên có thể phân công
 * Dùng để hiển thị trong danh sách chọn nhân viên
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeForAssignment {
    
    private String maNV;
    private String hoTen;
    private String sdt;
    private String chucVu;
    private Double soGioLamViecTrongTuan;
    
    /**
     * Helper method: Kiểm tra nhân viên có thời gian làm việc thấp không
     * Dùng để highlight trong UI
     */
    public boolean isLowWorkingHours() {
        return soGioLamViecTrongTuan != null && soGioLamViecTrongTuan < 10;
    }
    
    /**
     * Helper method: Format giờ làm việc để hiển thị
     */
    public String getFormattedWorkingHours() {
        if (soGioLamViecTrongTuan == null) {
            return "0";
        }
        return String.format("%.1f", soGioLamViecTrongTuan);
    }
    
    /**
     * Helper method: Lấy tên chức vụ
     */
    public String getTenChucVu() {
        if ("LT".equals(chucVu)) {
            return "Lái tàu";
        } else if ("TT".equals(chucVu)) {
            return "Toa tàu";
        }
        return chucVu;
    }
}