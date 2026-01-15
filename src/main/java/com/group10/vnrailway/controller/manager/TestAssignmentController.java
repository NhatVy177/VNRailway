package com.group10.vnrailway.controller.manager;

import com.group10.vnrailway.dto.TripAssignmentDetail;
import com.group10.vnrailway.dto.AssignmentStatistics;
import com.group10.vnrailway.dto.AssignmentInfo;
import com.group10.vnrailway.service.TripService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;

/**
 * COMPREHENSIVE DEBUG CONTROLLER
 * Test từng layer: Database → Repository → Service → Controller → Template
 */
@Controller
@RequiredArgsConstructor
@RequestMapping("/test/assignment")
public class TestAssignmentController {

    private final TripService tripService;

    // =============================================
    // LEVEL 1: Test data loading từ database
    // =============================================
    
    @GetMapping("/data/{tripId}")
    @ResponseBody
    public String testDataLoading(@PathVariable String tripId) {
        StringBuilder sb = new StringBuilder();
        sb.append("========================================\n");
        sb.append("TEST: DATA LOADING FROM DATABASE\n");
        sb.append("========================================\n\n");
        
        try {
            sb.append("Trip ID: ").append(tripId).append("\n\n");
            
            // Test 1: Trip Detail
            sb.append("1. Loading TripAssignmentDetail...\n");
            TripAssignmentDetail detail = tripService.getTripAssignmentDetail(tripId);
            if (detail != null) {
                sb.append("   ✓ SUCCESS\n");
                sb.append("   - MaChuyenTau: ").append(detail.getMaChuyenTau()).append("\n");
                sb.append("   - TenTuyen: ").append(detail.getTenTuyen()).append("\n");
                sb.append("   - ThoiGianXuatPhat: ").append(detail.getThoiGianXuatPhat()).append("\n");
            } else {
                sb.append("   ✗ FAILED: detail is NULL\n");
                return sb.toString();
            }
            
            sb.append("\n");
            
            // Test 2: Statistics
            sb.append("2. Loading AssignmentStatistics...\n");
            AssignmentStatistics stats = tripService.getAssignmentStatistics(tripId);
            if (stats != null) {
                sb.append("   ✓ SUCCESS\n");
                sb.append("   - TongSoViTri: ").append(stats.getTongSoViTri()).append("\n");
                sb.append("   - SoPhanCongDaCo: ").append(stats.getSoPhanCongDaCo()).append("\n");
                sb.append("   - SoConThieu: ").append(stats.getSoConThieu()).append("\n");
            } else {
                sb.append("   ✗ FAILED: stats is NULL\n");
                return sb.toString();
            }
            
            sb.append("\n");
            
            // Test 3: Assignments
            sb.append("3. Loading CurrentAssignments...\n");
            List<AssignmentInfo> assignments = tripService.getCurrentAssignments(tripId);
            if (assignments != null) {
                sb.append("   ✓ SUCCESS\n");
                sb.append("   - Total: ").append(assignments.size()).append(" items\n");
                
                if (!assignments.isEmpty()) {
                    sb.append("\n   First 5 items:\n");
                    for (int i = 0; i < Math.min(5, assignments.size()); i++) {
                        AssignmentInfo a = assignments.get(i);
                        sb.append("   ").append(i + 1).append(". ")
                          .append("VaiTro=").append(a.getVaiTro())
                          .append(", MaNV=").append(a.getMaNV())
                          .append(", TenNhanVien=").append(a.getTenNhanVien())
                          .append(", LoaiPhanCong=").append(a.getLoaiPhanCong())
                          .append("\n");
                    }
                }
            } else {
                sb.append("   ✗ FAILED: assignments is NULL\n");
            }
            
            sb.append("\n========================================\n");
            sb.append("CONCLUSION: All data loaded successfully!\n");
            sb.append("========================================\n");
            
        } catch (Exception e) {
            sb.append("\n❌ ERROR OCCURRED:\n");
            sb.append("Type: ").append(e.getClass().getName()).append("\n");
            sb.append("Message: ").append(e.getMessage()).append("\n");
            sb.append("\nStack trace:\n");
            for (StackTraceElement ste : e.getStackTrace()) {
                sb.append("  at ").append(ste.toString()).append("\n");
            }
        }
        
        return sb.toString();
    }

    // =============================================
    // LEVEL 2: Test with MOCK data (no database)
    // =============================================
    
    @GetMapping("/mock")
    public String testWithMockData(Model model) {
        System.out.println("========================================");
        System.out.println("TEST: MOCK DATA (NO DATABASE)");
        System.out.println("========================================");
        
        try {
            // Mock trip
            TripAssignmentDetail trip = new TripAssignmentDetail();
            trip.setMaChuyenTau("MOCK001");
            trip.setMaTuyen("TN01");
            trip.setTenTuyen("Mock Route");
            trip.setMaDoanTau("D001");
            trip.setTenTau("Mock Train");
            trip.setLoaiTau("S");
            trip.setThoiGianXuatPhat(LocalDateTime.now().plusDays(7));
            trip.setThoiGianDuKienDen(LocalDateTime.now().plusDays(8));
            trip.setSoVeDaBan(100);
            trip.setDoanhThu(50000000L);
            trip.setLaChuyenTuongLai(true);
            
            // Mock stats
            AssignmentStatistics stats = new AssignmentStatistics();
            stats.setTongSoViTri(10);
            stats.setSoPhanCongDaCo(3);
            stats.setSoConThieu(7);
            
            // Mock assignments (EMPTY LIST - test empty state)
            List<AssignmentInfo> assignments = new ArrayList<>();
            
            model.addAttribute("trip", trip);
            model.addAttribute("stats", stats);
            model.addAttribute("assignments", assignments);
            
            System.out.println("✓ Mock data created");
            System.out.println("✓ Returning template: pages/manager/assignments/trip-detail-future");
            System.out.println("========================================");
            
            return "pages/manager/assignments/trip-detail-future";
            
        } catch (Exception e) {
            System.err.println("❌ ERROR:");
            e.printStackTrace();
            model.addAttribute("errorMessage", e.getMessage());
            return "error/not-found";
        }
    }

    // =============================================
    // LEVEL 3: Test with REAL data + 3 assignments
    // =============================================
    
    @GetMapping("/real/{tripId}")
    public String testWithRealData(@PathVariable String tripId, Model model) {
        System.out.println("========================================");
        System.out.println("TEST: REAL DATA FROM DATABASE");
        System.out.println("TripId: " + tripId);
        System.out.println("========================================");
        
        try {
            // Load real data
            System.out.println("1. Loading trip detail...");
            TripAssignmentDetail detail = tripService.getTripAssignmentDetail(tripId);
            System.out.println("   ✓ Trip: " + detail.getMaChuyenTau());
            
            System.out.println("2. Loading statistics...");
            AssignmentStatistics stats = tripService.getAssignmentStatistics(tripId);
            System.out.println("   ✓ Stats: " + stats.getTongSoViTri() + " positions");
            
            System.out.println("3. Loading assignments...");
            List<AssignmentInfo> assignments = tripService.getCurrentAssignments(tripId);
            System.out.println("   ✓ Assignments: " + assignments.size() + " items");
            
            // Log first few assignments
            if (!assignments.isEmpty()) {
                System.out.println("\n   Assignment details:");
                for (int i = 0; i < Math.min(3, assignments.size()); i++) {
                    AssignmentInfo a = assignments.get(i);
                    System.out.println("   " + (i+1) + ". " + a.getVaiTro() + 
                        " → " + (a.getMaNV() != null ? a.getMaNV() : "EMPTY"));
                }
            }
            
            model.addAttribute("trip", detail);
            model.addAttribute("stats", stats);
            model.addAttribute("assignments", assignments);
            
            System.out.println("\n✓ All data loaded successfully");
            System.out.println("✓ Returning template: pages/manager/assignments/trip-detail-future");
            System.out.println("========================================");
            
            return "pages/manager/assignments/trip-detail-future";
            
        } catch (Exception e) {
            System.err.println("\n❌ ERROR:");
            System.err.println("Type: " + e.getClass().getName());
            System.err.println("Message: " + e.getMessage());
            e.printStackTrace();
            System.err.println("========================================");
            
            model.addAttribute("errorMessage", e.getMessage());
            return "error/not-found";
        }
    }

    // =============================================
    // LEVEL 4: Test template directly (minimal)
    // =============================================
    
    @GetMapping("/template-only")
    public String testTemplateOnly(Model model) {
        System.out.println("========================================");
        System.out.println("TEST: TEMPLATE RENDERING ONLY");
        System.out.println("========================================");
        
        // Absolute minimal data - just to test template exists
        TripAssignmentDetail trip = new TripAssignmentDetail();
        trip.setMaChuyenTau("TEST");
        trip.setTenTuyen("Test Route");
        trip.setTenTau("Test Train");
        trip.setThoiGianXuatPhat(LocalDateTime.now());
        trip.setThoiGianDuKienDen(LocalDateTime.now().plusHours(10));
        trip.setSoVeDaBan(0);
        trip.setDoanhThu(0L);
        
        AssignmentStatistics stats = new AssignmentStatistics();
        stats.setTongSoViTri(0);
        stats.setSoPhanCongDaCo(0);
        stats.setSoConThieu(0);
        
        List<AssignmentInfo> assignments = new ArrayList<>();
        
        model.addAttribute("trip", trip);
        model.addAttribute("stats", stats);
        model.addAttribute("assignments", assignments);
        
        return "pages/manager/assignments/trip-detail-future";
    }

    // =============================================
    // LEVEL 5: Check template file exists
    // =============================================
    
    @GetMapping("/check-template")
    @ResponseBody
    public String checkTemplate() {
        StringBuilder sb = new StringBuilder();
        sb.append("========================================\n");
        sb.append("TEMPLATE FILE CHECK\n");
        sb.append("========================================\n\n");
        
        String templatePath = "pages/manager/assignments/trip-detail-future";
        String fullPath = "templates/" + templatePath + ".html";
        
        try {
            org.springframework.core.io.Resource resource = 
                new org.springframework.core.io.ClassPathResource(fullPath);
            
            if (resource.exists()) {
                sb.append("✓ Template EXISTS\n");
                sb.append("  Path: ").append(fullPath).append("\n");
                sb.append("  URI: ").append(resource.getURI()).append("\n");
                sb.append("  File size: ").append(resource.contentLength()).append(" bytes\n");
            } else {
                sb.append("✗ Template NOT FOUND\n");
                sb.append("  Expected path: ").append(fullPath).append("\n");
            }
        } catch (Exception e) {
            sb.append("✗ ERROR checking template\n");
            sb.append("  Error: ").append(e.getMessage()).append("\n");
        }
        
        sb.append("\n========================================\n");
        return sb.toString();
    }
}