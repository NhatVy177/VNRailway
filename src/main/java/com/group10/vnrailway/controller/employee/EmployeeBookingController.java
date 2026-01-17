package com.group10.vnrailway.controller.employee;

import com.group10.vnrailway.request.OfflineBookingRequest;
import com.group10.vnrailway.security.user.CustomUserDetails;
import com.group10.vnrailway.service.BookingService;
import com.group10.vnrailway.service.TicketChangeService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

/**
 * Controller xử lý đặt vé offline cho nhân viên bán vé
 */
@Controller
@RequestMapping("/employee/booking")
public class EmployeeBookingController {

    @Autowired
    private BookingService bookingService;
    
    @Autowired
    private TicketChangeService ticketChangeService;

    /**
     * STEP 1: Hiển thị form nhập thông tin vé (có thêm form người đặt)
     * URL: POST /employee/booking/info
     */
    @PostMapping("/info")
    public String showBookingInfoPage(
            @RequestParam String maChuyenTau,
            @RequestParam String maGaDi,
            @RequestParam String maGaDen,
            @RequestParam String danhSachChoJson,
            @RequestParam(required = false) String maVeCu,
            Model model
    ) {
        System.out.println("=== EMPLOYEE BOOKING INFO PAGE ===");
        System.out.println("maVeCu: " + maVeCu);
        
        // Truyền dữ liệu sang view
        model.addAttribute("maChuyenTau", maChuyenTau);
        model.addAttribute("maGaDi", maGaDi);
        model.addAttribute("maGaDen", maGaDen);
        model.addAttribute("danhSachChoJson", danhSachChoJson);
        model.addAttribute("maVeCu", maVeCu != null ? maVeCu : "");
        
        // Nếu đang đổi vé, lấy thông tin vé cũ để tính phí
        if (maVeCu != null && !maVeCu.trim().isEmpty()) {
            try {
                System.out.println(">>> Lấy thông tin vé cũ: " + maVeCu.trim());
                var ticketInfo = ticketChangeService.layThongTinVeDeDoiVe(maVeCu.trim());
                
                if (ticketInfo != null) {
                    // Convert BigDecimal to double safely
                    double giaVeCu = ticketInfo.getGiaVeCu() != null 
                        ? ticketInfo.getGiaVeCu().doubleValue() : 0.0;
                    double phiDoiVe = ticketInfo.getPhiDoiVe() != null 
                        ? ticketInfo.getPhiDoiVe().doubleValue() : 0.0;
                    
                    System.out.println("GiaVeCu: " + giaVeCu + ", PhiDoiVe: " + phiDoiVe);
                    
                    model.addAttribute("giaVeCu", giaVeCu);
                    model.addAttribute("phiDoiVe", phiDoiVe);
                } else {
                    System.out.println(">>> ticketInfo is NULL");
                    model.addAttribute("giaVeCu", 0);
                    model.addAttribute("phiDoiVe", 0);
                }
            } catch (Exception e) {
                System.err.println(">>> ERROR loading ticket info: " + e.getMessage());
                e.printStackTrace();
                model.addAttribute("giaVeCu", 0);
                model.addAttribute("phiDoiVe", 0);
            }
        } else {
            model.addAttribute("giaVeCu", 0);
            model.addAttribute("phiDoiVe", 0);
        }
        
        // Sử dụng template cho nhân viên
        return "pages/employee/booking/booking-info"; 
    }

    /**
     * STEP 2: Xử lý đặt vé offline
     * URL: POST /employee/booking/create
     */
    @PostMapping("/create")
    public String createOfflineBooking(
            @ModelAttribute OfflineBookingRequest request,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            RedirectAttributes redirectAttributes
    ) {
        try {
            // Kiểm tra nhân viên đã đăng nhập
            if (userDetails == null) {
                redirectAttributes.addFlashAttribute("errorMessage", 
                    "Vui lòng đăng nhập");
                return "redirect:/login";
            }
            
            // Lấy mã nhân viên từ user đã đăng nhập
            String maNV = userDetails.getUserId();
            
            // Gọi service để tạo đơn đặt vé offline
            String maDon = bookingService.taoDonDatVeOffline(request, maNV);

            redirectAttributes.addFlashAttribute("successMessage", 
                "Đặt vé thành công! Mã đơn: " + maDon);
            redirectAttributes.addFlashAttribute("maDonMoi", maDon);
            
            return "redirect:/employee/bookings";

        } catch (Exception ex) {
            System.err.println("=== ERROR IN OFFLINE BOOKING ===");
            System.err.println("Error: " + ex.getMessage());
            ex.printStackTrace();
            
            redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage());
            return "redirect:/employee/bookings";
        }
    }
}
