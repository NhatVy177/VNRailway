package com.group10.vnrailway.controller.manager;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.group10.vnrailway.dto.EmployeeSalaryInfo;
import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.entity.ChinhSachLuong;
import com.group10.vnrailway.service.EmployeeService;

import java.util.List;

@Controller
@RequiredArgsConstructor
@RequestMapping("/manager/employees")
public class ManagerEmployeeController {

    private final EmployeeService employeeService;
    private static final int PAGE_SIZE = 10;

    /**
     * Hiển thị danh sách nhân viên với phân trang, lọc và sắp xếp
     */
    @GetMapping
    public String getEmployeeList(
            @RequestParam(required = false) String loaiNV,
            @RequestParam(required = false) String timKiem,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "TongLuong") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortOrder,
            @RequestParam(required = false) Integer thang,
            @RequestParam(required = false) Integer nam,
            Model model
    ) {
        PageResult<EmployeeSalaryInfo> pageResult = employeeService.getAllEmployeesWithSalary(
                loaiNV, timKiem, page, PAGE_SIZE, sortBy, sortOrder, thang, nam
        );
        
        List<ChinhSachLuong> salaryPolicies = employeeService.getAllSalaryPolicies();
        
        model.addAttribute("employees", pageResult.getData());
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", pageResult.getTotalPages());
        model.addAttribute("totalElements", pageResult.getTotalElements());
        model.addAttribute("loaiNV", loaiNV);
        model.addAttribute("timKiem", timKiem);
        model.addAttribute("sortBy", sortBy);
        model.addAttribute("sortOrder", sortOrder);
        model.addAttribute("thang", thang);
        model.addAttribute("nam", nam);
        model.addAttribute("salaryPolicies", salaryPolicies);
        
        return "pages/manager/employees/employee-list";
    }

    /**
     * Xem chi tiết thông tin lương của nhân viên
     */
    @GetMapping("/{maNV}")
    public String getEmployeeDetail(
            @PathVariable String maNV,
            @RequestParam(required = false) Integer thang,
            @RequestParam(required = false) Integer nam,
            Model model) {
        EmployeeSalaryInfo employee = employeeService.getEmployeeSalaryById(maNV, thang, nam)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy nhân viên: " + maNV));
        
        model.addAttribute("employee", employee);
        model.addAttribute("thang", thang);
        model.addAttribute("nam", nam);
        
        return "pages/manager/employees/employee-detail";
    }
}
