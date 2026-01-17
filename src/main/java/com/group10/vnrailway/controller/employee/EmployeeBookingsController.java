package com.group10.vnrailway.controller.employee;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

/**
 * Controller xử lý danh sách đơn đặt vé cho nhân viên bán vé
 */
@Controller
@RequestMapping("/employee/bookings")
public class EmployeeBookingsController {

    /**
     * Hiển thị danh sách đơn đặt vé
     */
    @GetMapping
    public String getBookings(Model model) {
        // TODO: Implement logic để hiển thị danh sách đơn đã đặt
        // Có thể hiển thị tất cả đơn hoặc chỉ đơn của nhân viên này
        
        return "pages/employee/bookings/employee-bookings";
    }
}
