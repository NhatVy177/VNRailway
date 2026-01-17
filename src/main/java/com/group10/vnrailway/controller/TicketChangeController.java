package com.group10.vnrailway.controller;

import com.group10.vnrailway.dto.TicketChangeDTO;
import com.group10.vnrailway.security.user.CustomUserDetails;
import com.group10.vnrailway.service.TicketChangeService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Map;

/**
 * TicketChangeController - Xử lý đổi vé
 */
@Controller
@RequestMapping("/ticket-change")
public class TicketChangeController {

    private final TicketChangeService ticketChangeService;

    public TicketChangeController(TicketChangeService ticketChangeService) {
        this.ticketChangeService = ticketChangeService;
    }

    /**
     * Hiển thị trang đổi vé - Bước 1: Xem thông tin vé và chọn loại đổi
     */
    @GetMapping("/{maVe}")
    public String showTicketChangeForm(
            @PathVariable String maVe,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            Model model,
            RedirectAttributes redirectAttributes
    ) {
        try {
            String maKH = userDetails.getUserId();
            boolean isEmployee = userDetails.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_TICKET_SELLER"));
            
            System.out.println("=== SHOW TICKET CHANGE FORM ===");
            System.out.println("User ID: " + maKH);
            System.out.println("Is Employee: " + isEmployee);
            
            // Lấy thông tin vé
            TicketChangeDTO ticket = ticketChangeService.layThongTinVeDeDoiVe(maVe);
            
            System.out.println("Ticket Owner (MaKH): " + ticket.getMaKH());
            
            // Kiểm tra quyền sở hữu (bỏ qua nếu là nhân viên)
            if (!isEmployee) {
                String ticketOwner = ticket.getMaKH() != null ? ticket.getMaKH().trim() : "";
                String currentUser = maKH != null ? maKH.trim() : "";
                
                System.out.println("Comparing: '" + ticketOwner + "' vs '" + currentUser + "'");
                
                if (!ticketOwner.equals(currentUser)) {
                    System.out.println(">>> ACCESS DENIED: User does not own this ticket");
                    redirectAttributes.addFlashAttribute("errorMessage", 
                        "Bạn không có quyền đổi vé này!");
                    return "redirect:/my-bookings";
                }
                System.out.println(">>> ACCESS GRANTED: User owns this ticket");
            } else {
                System.out.println(">>> ACCESS GRANTED: User is employee");
            }
            
            // Kiểm tra có được đổi vé không
            if (!ticket.getDuocDoiVe()) {
                redirectAttributes.addFlashAttribute("errorMessage", 
                    "Không thể đổi vé: " + ticket.getLyDoKhongDoiDuoc());
                return "redirect:/my-bookings";
            }
            
            model.addAttribute("ticket", ticket);
            return "pages/customer/booking/ticket-change-step1";
            
        } catch (Exception e) {
            System.err.println("Error loading ticket change form: " + e.getMessage());
            e.printStackTrace();
            
            redirectAttributes.addFlashAttribute("errorMessage", 
                "Lỗi tải thông tin vé: " + e.getMessage());
            return "redirect:/my-bookings";
        }
    }

    /**
     * Đổi vé trong cùng chuyến (đổi chỗ)
     */
    @PostMapping("/same-trip/{maVe}")
    public String changeSeatInSameTrip(
            @PathVariable String maVe,
            @RequestParam String maGheMoi,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            RedirectAttributes redirectAttributes
    ) {
        try {
            String maKH = userDetails.getUserId();
            boolean isEmployee = userDetails.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_TICKET_SELLER"));
            
            System.out.println("=== CHANGE SEAT IN SAME TRIP ===");
            System.out.println("User ID: " + maKH);
            System.out.println("Is Employee: " + isEmployee);
            
            // Kiểm tra quyền sở hữu (bỏ qua nếu là nhân viên)
            if (!isEmployee) {
                TicketChangeDTO ticket = ticketChangeService.layThongTinVeDeDoiVe(maVe);
                String ticketOwner = ticket.getMaKH() != null ? ticket.getMaKH().trim() : "";
                String currentUser = maKH != null ? maKH.trim() : "";
                
                System.out.println("Ticket Owner: '" + ticketOwner + "', Current User: '" + currentUser + "'");
                
                if (!ticketOwner.equals(currentUser)) {
                    redirectAttributes.addFlashAttribute("errorMessage", 
                        "Bạn không có quyền đổi vé này!");
                    return "redirect:/my-bookings";
                }
            }
            
            // Gọi stored procedure đổi vé
            Map<String, Object> result = ticketChangeService.doiVeTrongCungChuyen(maVe, maGheMoi);
            
            // Xử lý kết quả
            Integer returnCode = (Integer) result.get("#return_value");
            String thongBao = (String) result.get("ThongBao");
            String maVeMoi = (String) result.get("MaVeMoi");
            
            if (returnCode != null && returnCode < 0) {
                redirectAttributes.addFlashAttribute("errorMessage", thongBao);
            } else {
                redirectAttributes.addFlashAttribute("successMessage", 
                    "Đổi vé thành công! Mã vé mới: " + maVeMoi);
            }
            
        } catch (Exception e) {
            System.err.println("Error changing seat: " + e.getMessage());
            e.printStackTrace();
            
            redirectAttributes.addFlashAttribute("errorMessage", 
                "Lỗi đổi vé: " + e.getMessage());
        }
        
        return "redirect:/my-bookings";
    }

    /**
     * Đổi vé sang chuyến khác
     */
    @PostMapping("/different-trip/{maVe}")
    public String changeToAnotherTrip(
            @PathVariable String maVe,
            @RequestParam String maChuyenTauMoi,
            @RequestParam String maGheMoi,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            RedirectAttributes redirectAttributes
    ) {
        try {
            String maKH = userDetails.getUserId();
            boolean isEmployee = userDetails.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_TICKET_SELLER"));
            
            System.out.println("=== CHANGE TO DIFFERENT TRIP ===");
            System.out.println("User ID: " + maKH);
            System.out.println("Is Employee: " + isEmployee);
            
            // Kiểm tra quyền sở hữu (bỏ qua nếu là nhân viên)
            if (!isEmployee) {
                TicketChangeDTO ticket = ticketChangeService.layThongTinVeDeDoiVe(maVe);
                String ticketOwner = ticket.getMaKH() != null ? ticket.getMaKH().trim() : "";
                String currentUser = maKH != null ? maKH.trim() : "";
                
                System.out.println("Ticket Owner: '" + ticketOwner + "', Current User: '" + currentUser + "'");
                
                if (!ticketOwner.equals(currentUser)) {
                    redirectAttributes.addFlashAttribute("errorMessage", 
                        "Bạn không có quyền đổi vé này!");
                    return "redirect:/my-bookings";
                }
            }
            
            // Gọi stored procedure đổi vé
            Map<String, Object> result = ticketChangeService.doiVeSangChuyenKhac(
                maVe, maChuyenTauMoi, maGheMoi);
            
            // Xử lý kết quả
            Integer returnCode = (Integer) result.get("#return_value");
            String thongBao = (String) result.get("ThongBao");
            String maVeMoi = (String) result.get("MaVeMoi");
            String maDonMoi = (String) result.get("MaDonMoi");
            
            if (returnCode != null && returnCode < 0) {
                redirectAttributes.addFlashAttribute("errorMessage", thongBao);
            } else {
                redirectAttributes.addFlashAttribute("successMessage", 
                    "Đổi vé sang chuyến mới thành công! Mã vé mới: " + maVeMoi + ", Mã đơn mới: " + maDonMoi);
            }
            
        } catch (Exception e) {
            System.err.println("Error changing to different trip: " + e.getMessage());
            e.printStackTrace();
            
            redirectAttributes.addFlashAttribute("errorMessage", 
                "Lỗi đổi vé: " + e.getMessage());
        }
        
        return "redirect:/my-bookings";
    }
}
