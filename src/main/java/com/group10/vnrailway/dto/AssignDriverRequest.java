package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;

/**
 * Request DTO cho phân công lái tàu
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssignDriverRequest {
    
    @NotBlank(message = "Mã chuyến tàu không được để trống")
    private String maChuyenTau;
    
    @NotBlank(message = "Vai trò không được để trống")
    private String vaiTro; // "Lái chính" hoặc "Lái phụ"
    
    @NotBlank(message = "Mã nhân viên không được để trống")
    private String maNhanVien;
    
    @NotBlank(message = "Mã quản lý không được để trống")
    private String maNVQL;
}