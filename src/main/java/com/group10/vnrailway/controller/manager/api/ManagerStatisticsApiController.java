package com.group10.vnrailway.controller.manager.api;

import com.group10.vnrailway.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/manager/statistics")
@RequiredArgsConstructor
public class ManagerStatisticsApiController {

    private final StatisticsService statisticsService;

    // ========== REVENUE STATISTICS (TAB 1) ==========
    
    /**
     * Thống kê tổng hợp doanh thu
     * Gọi sp_ThongKeDoanhThu
     */
    @GetMapping("/revenue/summary")
    public ResponseEntity<Map<String, Object>> getRevenueSummary(
            @RequestParam("startDate") String startDate,
            @RequestParam("endDate") String endDate) {
        
        Map<String, Object> summary = statisticsService.getRevenueSummary(startDate, endDate);
        return ResponseEntity.ok(summary);
    }

    /**
     * Doanh thu theo tháng (cho biểu đồ)
     * Gọi sp_ThongKeDoanhThuTheoThang
     */
    @GetMapping("/revenue/by-month")
    public ResponseEntity<Map<String, Object>> getRevenueByMonth(
            @RequestParam("startDate") String startDate,
            @RequestParam("endDate") String endDate) {
        
        Map<String, Object> data = statisticsService.getRevenueByMonth(startDate, endDate);
        return ResponseEntity.ok(data);
    }

    /**
     * Số chuyến tàu theo tháng (cho biểu đồ)
     * Gọi sp_ThongKeChuyenTauTheoThang
     */
    @GetMapping("/revenue/trips-by-month")
    public ResponseEntity<Map<String, Object>> getTripsByMonth(
            @RequestParam("startDate") String startDate,
            @RequestParam("endDate") String endDate) {
        
        Map<String, Object> data = statisticsService.getTripsByMonth(startDate, endDate);
        return ResponseEntity.ok(data);
    }

    /**
     * Doanh thu theo tuyến
     * Gọi sp_ThongKeDoanhThuTheoTuyen
     */
    @GetMapping("/revenue/by-route")
    public ResponseEntity<Map<String, Object>> getRevenueByRoute(
            @RequestParam("startDate") String startDate,
            @RequestParam("endDate") String endDate) {
        
        Map<String, Object> data = statisticsService.getRevenueByRoute(startDate, endDate);
        return ResponseEntity.ok(data);
    }

    /**
     * Doanh thu theo loại chỗ
     * Gọi sp_ThongKeDoanhThuTheoLoaiCho
     */
    @GetMapping("/revenue/by-seat")
    public ResponseEntity<Map<String, Object>> getRevenueBySeat(
            @RequestParam("startDate") String startDate,
            @RequestParam("endDate") String endDate) {
        
        Map<String, Object> data = statisticsService.getRevenueBySeat(startDate, endDate);
        return ResponseEntity.ok(data);
    }

    /**
     * Lấy danh sách tuyến đường (cho dropdown)
     * Gọi sp_GetDanhSachTuyenDuong
     */
    @GetMapping("/routes")
    public ResponseEntity<Map<String, Object>> getRoutes() {
        Map<String, Object> routes = statisticsService.getRoutes();
        return ResponseEntity.ok(routes);
    }

    // ========== EMPLOYEE STATISTICS (TAB 2) ==========

    /**
     * Thống kê tổng hợp nhân viên theo tháng
     * Gọi sp_ThongKeNhanVienTheoThang
     */
    @GetMapping("/employees/summary")
    public ResponseEntity<Map<String, Object>> getEmployeeSummary(
            @RequestParam("month") int month,
            @RequestParam("year") int year) {
        
        Map<String, Object> summary = statisticsService.getEmployeeSummary(month, year);
        return ResponseEntity.ok(summary);
    }

    /**
     * Chi tiết thống kê từng nhân viên (có phân trang)
     * Gọi sp_ThongKeChiTietNhanVien
     */
    @GetMapping("/employees/detail")
    public ResponseEntity<Map<String, Object>> getEmployeeDetail(
            @RequestParam("month") int month,
            @RequestParam("year") int year,
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "size", defaultValue = "10") int size) {
        
        Map<String, Object> detail = statisticsService.getEmployeeDetail(month, year, page, size);
        return ResponseEntity.ok(detail);
    }

    /**
     * Thống kê theo bộ phận
     * Gọi sp_ThongKeNhanVienTheoBoPhan
     */
    @GetMapping("/employees/department")
    public ResponseEntity<Map<String, Object>> getEmployeeByDepartment(
            @RequestParam("month") int month,
            @RequestParam("year") int year) {
        
        Map<String, Object> department = statisticsService.getEmployeeByDepartment(month, year);
        return ResponseEntity.ok(department);
    }

    /**
     * Danh sách nhân viên vi phạm
     * Gọi sp_ThongKeViPhamNhanVien
     */
    @GetMapping("/employees/violation")
    public ResponseEntity<Map<String, Object>> getEmployeeViolation(
            @RequestParam("month") int month,
            @RequestParam("year") int year,
            @RequestParam(value = "threshold", defaultValue = "3") int threshold) {
        
        Map<String, Object> violation = statisticsService.getEmployeeViolation(month, year, threshold);
        return ResponseEntity.ok(violation);
    }
}
