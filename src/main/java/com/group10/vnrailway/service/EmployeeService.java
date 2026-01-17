package com.group10.vnrailway.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import com.group10.vnrailway.dto.EmployeeSalaryInfo;
import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.entity.ChinhSachLuong;
import com.group10.vnrailway.repository.EmployeeRepository;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class EmployeeService {

    private final EmployeeRepository employeeRepository;

    /**
     * Lấy danh sách nhân viên với phân trang, lọc và sắp xếp
     */
    public PageResult<EmployeeSalaryInfo> getAllEmployeesWithSalary(
            String loaiNV, String timKiem, int page, int pageSize,
            String sortBy, String sortOrder, Integer thang, Integer nam) {
        
        List<EmployeeSalaryInfo> employees = employeeRepository.getAllEmployeesWithSalary(
            loaiNV, timKiem, page, pageSize, sortBy, sortOrder, thang, nam);
        
        int totalElements = employeeRepository.countEmployees(loaiNV, timKiem);
        int totalPages = (int) Math.ceil((double) totalElements / pageSize);
        
        return new PageResult<>(employees, totalElements, totalPages, page);
    }

    /**
     * Lấy thông tin lương của một nhân viên
     */
    public Optional<EmployeeSalaryInfo> getEmployeeSalaryById(String maNV, Integer thang, Integer nam) {
        return employeeRepository.getEmployeeSalaryById(maNV, thang, nam);
    }

    /**
     * Lấy chính sách lương theo loại nhân viên
     */
    public Optional<ChinhSachLuong> getSalaryPolicyByType(String maLoaiNV) {
        return employeeRepository.getSalaryPolicyByType(maLoaiNV);
    }

    /**
     * Lấy tất cả chính sách lương
     */
    public List<ChinhSachLuong> getAllSalaryPolicies() {
        return employeeRepository.getAllSalaryPolicies();
    }
}
