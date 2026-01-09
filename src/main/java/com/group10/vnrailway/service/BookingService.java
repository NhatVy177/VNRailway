package com.group10.vnrailway.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.group10.vnrailway.dto.BookingTicket;
import com.group10.vnrailway.request.BookingRequest;
import com.group10.vnrailway.repository.BookingRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class BookingService {

    @Autowired
    private BookingRepository bookingRepository;

    private final ObjectMapper mapper = new ObjectMapper();

    /**
     * Tạo đơn đặt vé và trả về mã đơn
     * 
     * @param request BookingRequest chứa toàn bộ thông tin đặt vé
     * @return Mã đơn đặt vé (VD: DH000123)
     * @throws Exception nếu có lỗi trong quá trình đặt vé
     */
    public String taoDonDatVe(BookingRequest request) throws Exception {
        
        // 1. Validate input
        validateBookingRequest(request);
        
        // 2. Convert danh sách vé sang JSON
        String jsonDanhSachVe = convertTicketsToJson(request);
        
        // 3. Gọi stored procedure
        Map<String, Object> result = bookingRepository.callTaoDonDatVe(
                request.getMaChuyenTau(),
                request.getMaGaDi(),
                request.getMaGaDen(),
                request.getMaKHNguoiDat(),
                request.getPhuongThucTT(),
                jsonDanhSachVe
        );
        
        // 4. Xử lý kết quả
        return handleStoredProcedureResult(result);
    }

    /**
     * Validate thông tin booking request
     */
    private void validateBookingRequest(BookingRequest request) throws Exception {
        if (request == null) {
            throw new Exception("Booking request không được null");
        }
        
        if (request.getMaChuyenTau() == null || request.getMaChuyenTau().trim().isEmpty()) {
            throw new Exception("Mã chuyến tàu không được để trống");
        }
        
        if (request.getMaGaDi() == null || request.getMaGaDi().trim().isEmpty()) {
            throw new Exception("Mã ga đi không được để trống");
        }
        
        if (request.getMaGaDen() == null || request.getMaGaDen().trim().isEmpty()) {
            throw new Exception("Mã ga đến không được để trống");
        }
        
        if (request.getMaKHNguoiDat() == null || request.getMaKHNguoiDat().trim().isEmpty()) {
            throw new Exception("Mã khách hàng người đặt không được để trống");
        }
        
        if (request.getPhuongThucTT() == null || request.getPhuongThucTT().trim().isEmpty()) {
            throw new Exception("Phương thức thanh toán không được để trống");
        }
        
        if (request.getDanhSachVe() == null || request.getDanhSachVe().isEmpty()) {
            throw new Exception("Danh sách vé không được để trống");
        }
        
        // Validate từng vé
        for (int i = 0; i < request.getDanhSachVe().size(); i++) {
            BookingTicket ticket = request.getDanhSachVe().get(i);
            validateTicket(ticket, i);
        }
    }

    /**
     * Validate thông tin từng vé
     */
    private void validateTicket(BookingTicket ticket, int index) throws Exception {
        String prefix = "Vé " + (index + 1) + ": ";
        
        if (ticket.getMaToa() == null || ticket.getMaToa().trim().isEmpty()) {
            throw new Exception(prefix + "Mã toa không được để trống");
        }
        
        if (ticket.getMaCho() == null || ticket.getMaCho().trim().isEmpty()) {
            throw new Exception(prefix + "Mã chỗ không được để trống");
        }
        
        if (ticket.getMaThamSo() == null || ticket.getMaThamSo().trim().isEmpty()) {
            throw new Exception(prefix + "Mã tham số không được để trống");
        }
        
        if (ticket.getHoTen() == null || ticket.getHoTen().trim().isEmpty()) {
            throw new Exception(prefix + "Họ tên không được để trống");
        }
        
        if (ticket.getCmnd() == null || ticket.getCmnd().trim().isEmpty()) {
            throw new Exception(prefix + "CMND/CCCD không được để trống");
        }
        
        // Validate CMND format (9-12 số)
        String cmnd = ticket.getCmnd().trim();
        if (!cmnd.matches("\\d{9,12}")) {
            throw new Exception(prefix + "CMND/CCCD không hợp lệ (chỉ nhập số, 9-12 ký tự)");
        }
        
        // Validate SĐT nếu có
        if (ticket.getSdt() != null && !ticket.getSdt().trim().isEmpty()) {
            String sdt = ticket.getSdt().trim();
            if (!sdt.matches("0\\d{9}")) {
                throw new Exception(prefix + "Số điện thoại không hợp lệ (phải bắt đầu bằng 0 và có 10 số)");
            }
        }
    }

    /**
     * Convert danh sách vé sang JSON
     * Format phải khớp với stored procedure:
     * [{"maToa":"T001","maCho":"G023","maThamSo":"GV001","hoTen":"...","cmnd":"...","sdt":"...","ngSinh":"...","diaChi":"..."}]
     */
    private String convertTicketsToJson(BookingRequest request) throws Exception {
        try {
            return mapper.writeValueAsString(request.getDanhSachVe());
        } catch (Exception ex) {
            throw new Exception("Lỗi khi chuyển đổi danh sách vé sang JSON: " + ex.getMessage());
        }
    }

    /**
     * Xử lý kết quả trả về từ stored procedure
     * 
     * Result map chứa:
     * - #return_value: return code (0 = success, negative = error)
     * - MaDonMoi: mã đơn đặt vé (OUTPUT)
     * - ThongBao: thông báo (OUTPUT)
     */
    private String handleStoredProcedureResult(Map<String, Object> result) throws Exception {
        // Lấy return code
        Integer returnCode = (Integer) result.get("#return_value");
        String thongBao = (String) result.get("ThongBao");
        String maDonMoi = (String) result.get("MaDonMoi");
        
        // Log kết quả
        System.out.println("=== Stored Procedure Result ===");
        System.out.println("Return Code: " + returnCode);
        System.out.println("Thông báo: " + thongBao);
        System.out.println("Mã đơn: " + maDonMoi);
        System.out.println("===============================");
        
        // Kiểm tra return code
        if (returnCode == null || returnCode != 0) {
            // Có lỗi xảy ra
            String errorMessage = thongBao != null ? thongBao : "Lỗi không xác định khi đặt vé";
            throw new Exception(errorMessage);
        }
        
        // Thành công - trả về mã đơn
        if (maDonMoi == null || maDonMoi.trim().isEmpty()) {
            throw new Exception("Đặt vé thành công nhưng không nhận được mã đơn");
        }
        
        return maDonMoi.trim();
    }
}