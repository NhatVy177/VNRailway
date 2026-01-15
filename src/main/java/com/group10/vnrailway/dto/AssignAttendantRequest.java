package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;

/**
 * Request DTO cho phân công nhân viên toa tàu
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssignAttendantRequest {
    
    @NotBlank(message = "Mã chuyến tàu không được để trống")
    private String maChuyenTau;
    
    @NotBlank(message = "Vai trò không được để trống")
    private String vaiTro; // "Trưởng toa" hoặc "Nhân viên"
    
    @NotBlank(message = "Mã toa không được để trống")
    private String maToa;
    
    @NotBlank(message = "Mã nhân viên không được để trống")
    private String maNhanVien;
    
    @NotBlank(message = "Mã quản lý không được để trống")
    private String maNVQL;
}