package com.group10.vnrailway.controller.customer;

import com.group10.vnrailway.request.BookingRequest;
import com.group10.vnrailway.security.user.CustomUserDetails;
import com.group10.vnrailway.service.BookingService;
import com.group10.vnrailway.service.TicketChangeService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/booking")
public class CustomerBookingController {

    @Autowired
    private BookingService bookingService;
    
    @Autowired
    private TicketChangeService ticketChangeService;

    // ===============================
    // STEP 1: Hiển thị form nhập thông tin vé
    // ===============================
    /**
     * Nhận dữ liệu từ trip-detail.html (POST /booking/info)
     * 
     * @param maChuyenTau - Mã chuyến tàu (VD: SE2)
     * @param maGaDi - Mã ga đi (VD: SG)
     * @param maGaDen - Mã ga đến (VD: HN)
     * @param danhSachChoJson - JSON array chứa thông tin ghế đã chọn
     *        Format: [{"maToa":"T001","maCho":"G023","maThamSo":"GV001","giaGoc":1070000,...}]
     * @param model - Spring Model
     * @return booking-info.html
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
        System.out.println("=== BOOKING INFO PAGE ===");
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

        return "pages/customer/booking/booking-info"; 
    }

    // ===============================
    // STEP 2: Bấm "Đặt vé" → GỌI USP → REDIRECT MY-BOOKINGS
    // ===============================
    /**
     * Xử lý submit form đặt vé (POST /booking/create)
     * 
     * Lấy thông tin khách hàng từ user đang đăng nhập
     * 
     * @param request - BookingRequest chứa toàn bộ thông tin đặt vé
     * @param userDetails - Thông tin user từ Spring Security
     * @param redirectAttributes - Spring RedirectAttributes để truyền message
     * @return redirect:/my-bookings
     */
    @PostMapping("/create")
    public String createBooking(
            @ModelAttribute BookingRequest request,
            @RequestParam(required = false) String maVeCu,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            RedirectAttributes redirectAttributes
    ) {
        try {
            // Kiểm tra user đã đăng nhập
            if (userDetails == null) {
                redirectAttributes.addFlashAttribute("errorMessage", 
                    "Vui lòng đăng nhập để đặt vé");
                return "redirect:/login";
            }
            
            // Lấy mã khách hàng từ user đã đăng nhập
            String maKH = userDetails.getUserId();
            request.setMaKHNguoiDat(maKH);
            
            // Kiểm tra xem có phải đổi vé không
            if (maVeCu != null && !maVeCu.trim().isEmpty()) {
                // Đổi vé: Chỉ đổi 1 vé (lấy vé đầu tiên trong danh sách)
                if (request.getDanhSachVe() == null || request.getDanhSachVe().isEmpty()) {
                    throw new RuntimeException("Vui lòng chọn chỗ mới");
                }
                
                String maChoMoi = request.getDanhSachVe().get(0).getMaCho();
                
                // Gọi service đổi vé
                var result = ticketChangeService.doiVeTrongCungChuyen(maVeCu.trim(), maChoMoi);
                
                // Xử lý kết quả
                Integer returnCode = (Integer) result.get("#return_value");
                String thongBao = (String) result.get("ThongBao");
                String maVeMoi = (String) result.get("MaVeMoi");
                
                if (returnCode != null && returnCode < 0) {
                    redirectAttributes.addFlashAttribute("errorMessage", thongBao);
                } else {
                    redirectAttributes.addFlashAttribute("successMessage", 
                        "Đổi vé thành công! Mã vé mới: " + (maVeMoi != null ? maVeMoi.trim() : "N/A"));
                }
                
                return "redirect:/my-bookings";
            }
            
            // Đặt vé mới bình thường
            String maDon = bookingService.taoDonDatVe(request);

            // ⭐ THAY ĐỔI: Redirect đến my-bookings với flash attributes
            redirectAttributes.addFlashAttribute("successMessage", 
                "Đặt vé thành công! Mã đơn: " + maDon);
            redirectAttributes.addFlashAttribute("maDonMoi", maDon);
            redirectAttributes.addFlashAttribute("isNewBooking", true);
            
            return "redirect:/my-bookings";

        } catch (Exception ex) {
            // Log error
            System.err.println("=== ERROR IN BOOKING ===");
            System.err.println("Error type: " + ex.getClass().getName());
            System.err.println("Error message: " + ex.getMessage());
            ex.printStackTrace();
            System.err.println("========================");
            
            // Redirect đến my-bookings với error message
            redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage());
            
            return "redirect:/my-bookings";
        }
    }
    
    // ===============================
    // UTILITY ENDPOINTS (Optional)
    // ===============================
    
    /**
     * Test endpoint để xem thông tin booking request
     * URL: GET /booking/test
     */
    @GetMapping("/test")
    @ResponseBody
    public String testBooking() {
        return "Booking Controller is working! Use POST /booking/info to start booking process.";
    }
}