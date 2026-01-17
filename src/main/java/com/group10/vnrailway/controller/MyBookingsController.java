package com.group10.vnrailway.controller;

import com.group10.vnrailway.dto.MyBookingDTO;
import com.group10.vnrailway.security.user.CustomUserDetails;
import com.group10.vnrailway.service.MyBookingsService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Map;

/**
 * MyBookingsController - Hiển thị danh sách vé đã đặt của khách hàng
 */
@Controller
public class MyBookingsController {

    private final MyBookingsService myBookingsService;

    public MyBookingsController(MyBookingsService myBookingsService) {
        this.myBookingsService = myBookingsService;
    }

    /**
     * Hiển thị trang danh sách vé đã đặt
     * 
     * Flash Attributes nhận được từ BookingController:
     * - successMessage: "Đặt vé thành công! Mã đơn: DH000123"
     * - errorMessage: "Đặt vé thất bại: ..."
     * - maDonMoi: "DH000123"
     * - isNewBooking: true (để hiển thị warning thanh toán)
     * 
     * @param userDetails - Thông tin user từ Spring Security
     * @param model - Spring Model
     * @return my-bookings.html
     */
    @GetMapping("/my-bookings")
    public String showMyBookings(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            Model model
    ) {
        try {
            // Lấy mã khách hàng từ authenticated user
            String maKH = userDetails.getUserId(); // Lấy MaNguoiDung (U000001, U000010, ...)
            
            // Lấy danh sách vé đã đặt, nhóm theo đơn
            Map<String, List<MyBookingDTO>> bookingsByOrder = 
                    myBookingsService.getDanhSachVeDaDatTheoKhachHang(maKH);
            
            // Thêm vào model
            model.addAttribute("bookingsByOrder", bookingsByOrder);
            model.addAttribute("paymentDeadlineHours", 24);
            
        } catch (Exception e) {
            // Log lỗi
            System.err.println("Error loading bookings: " + e.getMessage());
            e.printStackTrace();
            
            // Thêm error message
            model.addAttribute("errorMessage", "Không thể tải danh sách vé: " + e.getMessage());
        }
        
        return "pages/customer/booking/my-bookings";
    }

    /**
     * Xử lý thanh toán đơn đặt vé
     * 
     * @param maDon - Mã đơn đặt vé cần thanh toán
     * @param userDetails - Thông tin user từ Spring Security
     * @param redirectAttributes - Flash attributes
     * @return redirect về trang my-bookings
     */
    @PostMapping("/my-bookings/pay/{maDon}")
    public String thanhToanDon(
            @PathVariable String maDon,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            RedirectAttributes redirectAttributes
    ) {
        try {
            String maKH = userDetails.getUserId();
            
            // Gọi service xử lý thanh toán
            boolean success = myBookingsService.thanhToanDon(maDon, maKH);
            
            if (success) {
                redirectAttributes.addFlashAttribute("successMessage", 
                    "Thanh toán thành công cho đơn hàng " + maDon + "!");
            } else {
                redirectAttributes.addFlashAttribute("errorMessage", 
                    "Không thể thanh toán đơn hàng " + maDon + ". Vui lòng thử lại.");
            }
            
        } catch (Exception e) {
            System.err.println("Error processing payment: " + e.getMessage());
            e.printStackTrace();
            
            redirectAttributes.addFlashAttribute("errorMessage", 
                "Lỗi xử lý thanh toán: " + e.getMessage());
        }
        
        return "redirect:/my-bookings";
    }

    /**
     * Xử lý thanh toán từng vé riêng lẻ
     * 
     * @param maVe - Mã vé cần thanh toán
     * @param userDetails - Thông tin user từ Spring Security
     * @param redirectAttributes - Flash attributes
     * @return redirect về trang my-bookings
     */
    @PostMapping("/my-bookings/pay-ticket/{maVe}")
    public String thanhToanVe(
            @PathVariable String maVe,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            RedirectAttributes redirectAttributes
    ) {
        try {
            String maKH = userDetails.getUserId();
            
            // Gọi service xử lý thanh toán vé
            boolean success = myBookingsService.thanhToanVe(maVe, maKH);
            
            if (success) {
                redirectAttributes.addFlashAttribute("successMessage", 
                    "Thanh toán thành công cho vé " + maVe + "!");
            } else {
                redirectAttributes.addFlashAttribute("errorMessage", 
                    "Không thể thanh toán vé " + maVe + ". Vui lòng thử lại.");
            }
            
        } catch (Exception e) {
            System.err.println("Error processing ticket payment: " + e.getMessage());
            e.printStackTrace();
            
            redirectAttributes.addFlashAttribute("errorMessage", 
                "Lỗi xử lý thanh toán vé: " + e.getMessage());
        }
        
        return "redirect:/my-bookings";
    }
}