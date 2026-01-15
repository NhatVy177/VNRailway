package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;

/**
 * Request DTO cho duyệt nghỉ phép và phân công người thay thế
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApproveLeaveRequest {
    
    @NotBlank(message = "Mã chuyến tàu không được để trống")
    private String maChuyenTau;
    
    @NotBlank(message = "Mã nhân viên nghỉ phép không được để trống")
    private String maNhanVienNghiPhep;
    
    @NotBlank(message = "Mã nhân viên thay thế không được để trống")
    private String maNhanVienThayThe;
    
    @NotBlank(message = "Mã quản lý không được để trống")
    private String maNVQL;
}