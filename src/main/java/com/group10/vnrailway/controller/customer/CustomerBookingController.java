package com.group10.vnrailway.controller.customer;

import com.group10.vnrailway.request.BookingRequest;
import com.group10.vnrailway.service.BookingService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/booking")
public class CustomerBookingController {

    @Autowired
    private BookingService bookingService;

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
            Model model
    ) {
        // Truyền dữ liệu sang view
        model.addAttribute("maChuyenTau", maChuyenTau);
        model.addAttribute("maGaDi", maGaDi);
        model.addAttribute("maGaDen", maGaDen);
        model.addAttribute("danhSachChoJson", danhSachChoJson);

        return "pages/customer/booking/booking-info"; 
    }

    // ===============================
    // STEP 2: Bấm "Đặt vé" → GỌI USP → REDIRECT MY-BOOKINGS
    // ===============================
    /**
     * Xử lý submit form đặt vé (POST /booking/create)
     * 
     * ⭐ THAY ĐỔI: Redirect đến /my-bookings thay vì success/error page
     * 
     * @param request - BookingRequest chứa toàn bộ thông tin đặt vé
     * @param redirectAttributes - Spring RedirectAttributes để truyền message
     * @return redirect:/my-bookings
     */
    @PostMapping("/create")
    public String createBooking(
            @ModelAttribute BookingRequest request,
            RedirectAttributes redirectAttributes
    ) {
        try {
            // ⭐ HARDCODE maKHNguoiDat tạm thời
            // TODO: Sau này lấy từ Spring Security / Session khi có login
            request.setMaKHNguoiDat("U000010");
            
            // Gọi service để tạo đơn đặt vé
            String maDon = bookingService.taoDonDatVe(request);

            // ⭐ THAY ĐỔI: Redirect đến my-bookings với flash attributes
            redirectAttributes.addFlashAttribute("successMessage", 
                "Đặt vé thành công! Mã đơn: " + maDon);
            redirectAttributes.addFlashAttribute("maDonMoi", maDon);
            redirectAttributes.addFlashAttribute("isNewBooking", true);
            
            return "redirect:/my-bookings";

        } catch (Exception ex) {
            // Log error
            System.err.println("Error creating booking: " + ex.getMessage());
            ex.printStackTrace();
            
            // ⭐ THAY ĐỔI: Redirect đến my-bookings với error message
            redirectAttributes.addFlashAttribute("errorMessage", 
                "Đặt vé thất bại: " + ex.getMessage());
            
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