package com.group10.vnrailway.controller.manager;

import com.group10.vnrailway.dto.TripAssignmentList;
import com.group10.vnrailway.exception.BusinessException;
import com.group10.vnrailway.dto.TripAssignmentDetail;
import com.group10.vnrailway.dto.ApproveLeaveRequest;
import com.group10.vnrailway.dto.AssignAttendantRequest;
import com.group10.vnrailway.dto.AssignDriverRequest;
import com.group10.vnrailway.dto.AssignmentStatistics;
import com.group10.vnrailway.dto.EmployeeForAssignment;
import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.service.TripService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import com.group10.vnrailway.dto.EmployeeForAssignment;
import com.group10.vnrailway.dto.AssignmentInfo;
import com.group10.vnrailway.dto.AssignDriverRequest;
import com.group10.vnrailway.dto.AssignAttendantRequest;
import com.group10.vnrailway.dto.ApproveLeaveRequest;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import java.security.Principal;

import java.security.Principal;
import java.time.LocalDate;
import java.util.List;

/**
 * Controller xử lý phân công nhân viên cho chuyến tàu
 */
@Controller
@RequiredArgsConstructor
@RequestMapping("/manager/assignments")
public class ManagerAssignmentController {

    private final TripService tripService;

    private static final int PAGE_SIZE = 10;

    /**
     * Hiển thị trang danh sách chuyến tàu cho phân công
     */
    @GetMapping
    public String getAssignmentListPage(
            @RequestParam(defaultValue = "0") int page,
            Model model) {

        PageResult<TripAssignmentList> pageResult = tripService.getTripsForAssignmentPaged(
                null, null, null, null, null, page, PAGE_SIZE
        );

        model.addAttribute("trips", pageResult.getData());
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", pageResult.getTotalPages());
        model.addAttribute("totalItems", pageResult.getTotalElements());
        return "pages/manager/assignments/trip-list";
    }

    /**
     * Tìm kiếm chuyến tàu cho phân công
     */
    @PostMapping("/search")
    public String searchTrips(
            @RequestParam(required = false) String maChuyenTau,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate ngayKhoiHanhTu,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate ngayKhoiHanhDen,
            @RequestParam(required = false) String loaiTau,
            @RequestParam(required = false) String trangThai,
            @RequestParam(defaultValue = "0") int page,
            Model model) {

        // Convert empty strings to null
        maChuyenTau = (maChuyenTau != null && maChuyenTau.trim().isEmpty()) ? null : maChuyenTau;
        loaiTau = (loaiTau != null && loaiTau.trim().isEmpty()) ? null : loaiTau;
        trangThai = (trangThai != null && trangThai.trim().isEmpty()) ? null : trangThai;

        PageResult<TripAssignmentList> pageResult = tripService.getTripsForAssignmentPaged(
                maChuyenTau, ngayKhoiHanhTu, ngayKhoiHanhDen, loaiTau, trangThai, page, PAGE_SIZE
        );

        model.addAttribute("trips", pageResult.getData());
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", pageResult.getTotalPages());
        model.addAttribute("totalItems", pageResult.getTotalElements());
        model.addAttribute("maChuyenTau", maChuyenTau);
        model.addAttribute("ngayKhoiHanhTu", ngayKhoiHanhTu);
        model.addAttribute("ngayKhoiHanhDen", ngayKhoiHanhDen);
        model.addAttribute("loaiTau", loaiTau);
        model.addAttribute("trangThai", trangThai);

        return "pages/manager/assignments/trip-list";
    }

    /**
     * Hiển thị danh sách nhân viên có thể phân công
     * URL: /manager/assignments/{tripId}/employees?type=laitau&role=lai-chinh
     */
    @GetMapping("/{maChuyenTau}/employees")
    public String getEmployeeList(
            @PathVariable String maChuyenTau,
            @RequestParam String type, // 'laitau' hoặc 'toatau'
            @RequestParam(required = false) String role, // 'lai-chinh', 'lai-phu', etc.
            @RequestParam(required = false) String toa, // Mã toa (nếu là toa tàu)
            @RequestParam(required = false) String search, // Từ khóa tìm kiếm
            @RequestParam(required = false, defaultValue = "1") int page,
            @RequestParam(required = false, defaultValue = "10") int size,
            Model model) {
        
        try {
            // Trim mã chuyến tàu
            String trimmedMaChuyenTau = maChuyenTau.trim();
            
            // Lấy danh sách nhân viên (có hỗ trợ search)
            List<EmployeeForAssignment> employees = 
                tripService.getEmployeesForAssignment(trimmedMaChuyenTau, type, search);
            
            // Lấy thông tin chuyến tàu (để hiển thị header)
            TripAssignmentDetail trip = tripService.getTripAssignmentDetail(trimmedMaChuyenTau);
            
            // Pagination logic
            int totalElements = employees.size();
            int totalPages = (int) Math.ceil((double) totalElements / size);
            int fromIndex = Math.min((page - 1) * size, totalElements);
            int toIndex = Math.min(fromIndex + size, totalElements);
            List<EmployeeForAssignment> pageData = employees.subList(fromIndex, toIndex);
            
            // Add attributes
            model.addAttribute("employees", pageData);
            model.addAttribute("trip", trip);
            model.addAttribute("type", type);
            model.addAttribute("role", role);
            model.addAttribute("toa", toa);
            model.addAttribute("search", search);
            model.addAttribute("page", page);
            model.addAttribute("size", size);
            model.addAttribute("totalElements", totalElements);
            model.addAttribute("totalPages", totalPages);
            
            return "pages/manager/assignments/employee-list";
            
        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("errorMessage", "Lỗi: " + e.getMessage());
            return "error/not-found";
        }
    }

    /**
     * Phân công lái tàu
     * POST /manager/assignments/{tripId}/assign-driver
     */
    @PostMapping("/{maChuyenTau}/assign-driver")
    public String assignDriver(
            @PathVariable String maChuyenTau,
            @RequestParam String vaiTro,
            @RequestParam String maNhanVien,
            Principal principal,
            RedirectAttributes redirectAttributes) {
        
        try {
            // Lấy mã quản lý từ principal
            String maNVQL = principal.getName();
            
            // Tạo request
            AssignDriverRequest request = new AssignDriverRequest(
                maChuyenTau.trim(),
                vaiTro,
                maNhanVien.trim(),
                maNVQL
            );
            
            // Gọi service
            tripService.assignDriver(request);
            
            // Success message
            redirectAttributes.addFlashAttribute("successMessage", 
                "Phân công lái tàu thành công!");
            
            return "redirect:/manager/assignments/" + maChuyenTau;
            
        } catch (BusinessException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/manager/assignments/" + maChuyenTau;
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "Lỗi hệ thống");
            return "redirect:/manager/assignments/" + maChuyenTau;
        }
    }

    /**
     * Phân công nhân viên toa tàu
     * POST /manager/assignments/{tripId}/assign-attendant
     */
    @PostMapping("/{maChuyenTau}/assign-attendant")
    public String assignAttendant(
            @PathVariable String maChuyenTau,
            @RequestParam String vaiTro,
            @RequestParam String maToa,
            @RequestParam String maNhanVien,
            Principal principal,
            RedirectAttributes redirectAttributes) {
        
        try {
            // Lấy mã quản lý từ principal
            String maNVQL = principal.getName();
            
            // Tạo request
            AssignAttendantRequest request = new AssignAttendantRequest(
                maChuyenTau.trim(),
                vaiTro,
                maToa.trim(),
                maNhanVien.trim(),
                maNVQL
            );
            
            // Gọi service
            tripService.assignAttendant(request);
            
            // Success message
            redirectAttributes.addFlashAttribute("successMessage", 
                "Phân công nhân viên toa tàu thành công!");
            
            return "redirect:/manager/assignments/" + maChuyenTau;
            
        } catch (BusinessException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/manager/assignments/" + maChuyenTau;
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "Lỗi hệ thống");
            return "redirect:/manager/assignments/" + maChuyenTau;
        }
    }

    /**
     * Duyệt nghỉ phép và phân công người thay thế
     * POST /manager/assignments/{tripId}/approve-leave
     */
    @PostMapping("/{maChuyenTau}/approve-leave")
    public String approveLeave(
            @PathVariable String maChuyenTau,
            @RequestParam String maNhanVienNghiPhep,
            @RequestParam String maNhanVienThayThe,
            Principal principal,
            RedirectAttributes redirectAttributes) {
        
        try {
            // Lấy mã quản lý từ principal
            String maNVQL = principal.getName();
            
            // Tạo request
            ApproveLeaveRequest request = new ApproveLeaveRequest(
                maChuyenTau.trim(),
                maNhanVienNghiPhep.trim(),
                maNhanVienThayThe.trim(),
                maNVQL
            );
            
            // Gọi service
            tripService.approveLeaveAndAssignReplacement(request);
            
            // Success message
            redirectAttributes.addFlashAttribute("successMessage", 
                "Duyệt nghỉ phép và phân công người thay thế thành công!");
            
            return "redirect:/manager/assignments/" + maChuyenTau;
            
        } catch (BusinessException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/manager/assignments/" + maChuyenTau;
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "Lỗi hệ thống");
            return "redirect:/manager/assignments/" + maChuyenTau;
        }
    }
    /**
     * Hiển thị chi tiết chuyến tàu phân công
     * CẬP NHẬT: Thêm danh sách phân công hiện tại
     */
    @GetMapping("/{maChuyenTau}")
    public String getTripDetail(
            @PathVariable String maChuyenTau,
            Model model) {

        try {
            String trimmedMaChuyenTau = maChuyenTau.trim();
            
            System.out.println("========== TRIP DETAIL REQUEST ==========");
            System.out.println("Mã chuyến tàu: " + trimmedMaChuyenTau);
            
            // Lấy chi tiết chuyến
            TripAssignmentDetail detail = tripService.getTripAssignmentDetail(trimmedMaChuyenTau);
            System.out.println("✓ Detail loaded: " + (detail != null));
            System.out.println("  - Tên tuyến: " + (detail != null ? detail.getTenTuyen() : "null"));
            System.out.println("  - Là chuyến tương lai: " + (detail != null ? detail.getLaChuyenTuongLai() : "null"));
            
            // Lấy thống kê
            AssignmentStatistics stats = tripService.getAssignmentStatistics(trimmedMaChuyenTau);
            System.out.println("✓ Stats loaded: " + (stats != null));
            
            // ✅ THÊM: Lấy danh sách phân công hiện tại
            List<AssignmentInfo> assignments = tripService.getCurrentAssignments(trimmedMaChuyenTau);
            System.out.println("✓ Assignments loaded: " + (assignments != null ? assignments.size() : 0) + " items");

            model.addAttribute("trip", detail);
            model.addAttribute("stats", stats);
            model.addAttribute("assignments", assignments); // ✅ THÊM

            String templateName;
            if (detail.getLaChuyenTuongLai()) {
                templateName = "pages/manager/assignments/trip-detail-future";
            } else {
                templateName = "pages/manager/assignments/trip-detail-past";
            }
            
            System.out.println("✓ Returning template: " + templateName);
            System.out.println("=========================================\n");
            
            return templateName;
            
        } catch (Exception e) {
            System.err.println("❌ ERROR in getTripDetail:");
            e.printStackTrace();
            model.addAttribute("errorMessage", "Lỗi: " + e.getMessage());
            return "error/not-found";
        }
    }
}