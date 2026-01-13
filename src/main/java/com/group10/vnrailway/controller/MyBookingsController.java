package com.group10.vnrailway.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * MyBookingsController - Stub version
 * 
 * Mục đích: Test redirect từ BookingController
 * 
 * TODO: Sau này sẽ implement đầy đủ:
 * - Query database để lấy danh sách vé của user
 * - Phân trang
 * - Filter theo trạng thái (đã/chưa thanh toán)
 * - Button thanh toán
 */
@Controller
public class MyBookingsController {

    /**
     * Hiển thị trang danh sách vé đã đặt
     * 
     * Flash Attributes nhận được từ BookingController:
     * - successMessage: "Đặt vé thành công! Mã đơn: DH000123"
     * - errorMessage: "Đặt vé thất bại: ..."
     * - maDonMoi: "DH000123"
     * - isNewBooking: true (để hiển thị warning thanh toán)
     * 
     * @param model Spring Model (Flash attributes tự động inject)
     * @return my-bookings.html
     */
    @GetMapping("/my-bookings")
    public String showMyBookings(Model model) {
        
        // ⭐ Flash attributes đã tự động có trong model
        // Không cần làm gì thêm, chỉ return view
        
        // TODO: Sau này thêm logic:
        // 1. Lấy maKH từ session/security
        // 2. Query database: sp_LayDanhSachVeDaDat
        // 3. Query THAM_SO TS002 (thời gian thanh toán)
        // 4. Add vào model
        
        // Tạm thời hardcode để test
        model.addAttribute("paymentDeadlineHours", 24);
        
        return "pages/booking/my-bookings";
    }
}