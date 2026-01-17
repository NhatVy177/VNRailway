package com.group10.vnrailway.controller.employee;

import com.group10.vnrailway.dto.MyBookingDTO;
import com.group10.vnrailway.security.user.CustomUserDetails;
import com.group10.vnrailway.service.MyBookingsService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Map;

/**
 * EmployeeBookingLookupController - Tra cứu vé đã đặt của khách hàng
 * Dành cho nhân viên bán vé
 */
@Controller
@RequestMapping("/employee/bookings")
public class EmployeeBookingLookupController {

    private final MyBookingsService myBookingsService;

    public EmployeeBookingLookupController(MyBookingsService myBookingsService) {
        this.myBookingsService = myBookingsService;
    }

    /**
     * Hiển thị trang tra cứu vé
     * 
     * @param userDetails - Thông tin nhân viên đăng nhập
     * @param model - Spring Model
     * @return employee-booking-search.html
     */
    @GetMapping("/search")
    public String showSearchPage(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            Model model
    ) {
        // Chỉ hiển thị form tìm kiếm ban đầu
        return "pages/employee/bookings/employee-booking-search";
    }

    /**
     * Xử lý tìm kiếm vé theo số điện thoại hoặc CMND
     * 
     * @param soDienThoai - Số điện thoại người đặt (optional)
     * @param cmnd - CMND người đặt (optional)
     * @param userDetails - Thông tin nhân viên đăng nhập
     * @param model - Spring Model
     * @return employee-booking-search.html với kết quả
     */
    @PostMapping("/search")
    public String searchBookings(
            @RequestParam(required = false) String soDienThoai,
            @RequestParam(required = false) String cmnd,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            Model model
    ) {
        try {
            // Kiểm tra ít nhất 1 tham số phải có
            if ((soDienThoai == null || soDienThoai.trim().isEmpty()) 
                && (cmnd == null || cmnd.trim().isEmpty())) {
                model.addAttribute("errorMessage", "Vui lòng nhập số điện thoại hoặc CMND để tìm kiếm!");
                return "pages/employee/bookings/employee-booking-search";
            }
            
            // Chuẩn hóa input
            String sdt = (soDienThoai != null && !soDienThoai.trim().isEmpty()) 
                    ? soDienThoai.trim() : null;
            String cmndTrim = (cmnd != null && !cmnd.trim().isEmpty()) 
                    ? cmnd.trim() : null;
            
            // Tìm kiếm vé
            Map<String, List<MyBookingDTO>> bookingsByOrder = 
                    myBookingsService.getDanhSachVeTheoSoDienThoaiHoacCMND(sdt, cmndTrim);
            
            // Kiểm tra có kết quả không
            if (bookingsByOrder.isEmpty()) {
                model.addAttribute("warningMessage", 
                    "Không tìm thấy vé nào với thông tin: " + 
                    (sdt != null ? "SĐT: " + sdt : "CMND: " + cmndTrim));
            } else {
                model.addAttribute("successMessage", 
                    "Tìm thấy " + bookingsByOrder.size() + " đơn đặt vé");
            }
            
            // Thêm vào model
            model.addAttribute("bookingsByOrder", bookingsByOrder);
            model.addAttribute("paymentDeadlineHours", 24);
            model.addAttribute("soDienThoai", sdt);
            model.addAttribute("cmnd", cmndTrim);
            
        } catch (Exception e) {
            System.err.println("Error searching bookings: " + e.getMessage());
            e.printStackTrace();
            
            model.addAttribute("errorMessage", "Lỗi khi tìm kiếm: " + e.getMessage());
        }
        
        return "pages/employee/bookings/employee-booking-search";
    }

    /**
     * Xử lý thanh toán đơn đặt vé - dành cho nhân viên
     * (Tái sử dụng logic của MyBookingsController)
     * 
     * @param maDon - Mã đơn đặt vé cần thanh toán
     * @param userDetails - Thông tin nhân viên
     * @param redirectAttributes - Flash attributes
     * @return redirect về trang search với thông tin tìm kiếm trước đó
     */
    @PostMapping("/pay")
    public String thanhToanDon(
            @RequestParam String maDon,
            @RequestParam(required = false) String soDienThoai,
            @RequestParam(required = false) String cmnd,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            RedirectAttributes redirectAttributes
    ) {
        try {
            // Lấy thông tin khách hàng từ đơn đặt vé
            // NOTE: Service cần được cập nhật để không cần maKH
            boolean success = myBookingsService.thanhToanDon(maDon, null);
            
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
        
        // Redirect về trang search, giữ lại tham số tìm kiếm
        String redirectUrl = "/employee/bookings/search";
        if (soDienThoai != null && !soDienThoai.isEmpty()) {
            redirectUrl += "?soDienThoai=" + soDienThoai;
        } else if (cmnd != null && !cmnd.isEmpty()) {
            redirectUrl += "?cmnd=" + cmnd;
        }
        
        return "redirect:" + redirectUrl;
    }
}
