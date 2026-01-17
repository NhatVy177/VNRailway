package com.group10.vnrailway.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.group10.vnrailway.dto.BookingTicket;
import com.group10.vnrailway.request.BookingRequest;
import com.group10.vnrailway.request.OfflineBookingRequest;
import com.group10.vnrailway.repository.BookingRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

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

        // Validate CMND không trùng lặp
        validateUniqueCMND(request.getDanhSachVe());
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
        
        // Allow NULL maThamSo (no discount for regular customers), but reject pure whitespace
        if (ticket.getMaThamSo() != null && ticket.getMaThamSo().trim().isEmpty()) {
            throw new Exception(prefix + "Mã tham số không hợp lệ (không được để trống chuỗi khoảng trắng)");
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
     * Validate CMND không trùng lặp trong cùng một đơn đặt vé
     * Quy định: Mỗi CMND chỉ được đặt 1 ghế duy nhất trong cùng một đơn
     */
    private void validateUniqueCMND(List<BookingTicket> tickets) throws Exception {
        Set<String> cmndSet = new HashSet<>();

        for (int i = 0; i < tickets.size(); i++) {
            String cmnd = tickets.get(i).getCmnd().trim();

            if (cmndSet.contains(cmnd)) {
                throw new Exception("CMND/CCCD \"" + cmnd + "\" bị trùng lặp! " +
                    "Quy định: Mỗi CMND chỉ được đặt 1 ghế duy nhất trong cùng một đơn.");
            }

            cmndSet.add(cmnd);
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
        
        // Kiểm tra return code (0 = success, negative = error)
        if (returnCode == null || returnCode < 0) {
            // Có lỗi xảy ra
            String errorMessage = thongBao != null ? thongBao : "Lỗi không xác định khi đặt vé";
            throw new Exception(errorMessage);
        }
        
        // Thành công (returnCode == 0) - trả về mã đơn
        if (maDonMoi == null || maDonMoi.trim().isEmpty()) {
            throw new Exception("Đặt vé thành công nhưng không nhận được mã đơn");
        }
        
        return maDonMoi.trim();
    }

    /**
     * Tạo đơn đặt vé offline cho nhân viên bán vé
     * 
     * @param request OfflineBookingRequest chứa thông tin đặt vé và thông tin người đặt
     * @param maNV Mã nhân viên bán vé
     * @return Mã đơn đặt vé
     * @throws Exception nếu có lỗi
     */
    public String taoDonDatVeOffline(OfflineBookingRequest request, String maNV) throws Exception {
        
        // 1. Validate input
        validateOfflineBookingRequest(request, maNV);
        
        // 2. Convert danh sách vé sang JSON
        String jsonDanhSachVe = convertOfflineTicketsToJson(request);
        
        // 3. Gọi stored procedure offline
        Map<String, Object> result = bookingRepository.callTaoDonDatVeOffline(
                request.getMaChuyenTau(),
                request.getMaGaDi(),
                request.getMaGaDen(),
                maNV,
                request.getPhuongThucTT(),
                jsonDanhSachVe,
                request.getNguoiDatHoTen(),
                request.getNguoiDatCMND()
        );
        
        // 4. Xử lý kết quả
        return handleStoredProcedureResult(result);
    }

    /**
     * Validate thông tin offline booking request
     */
    private void validateOfflineBookingRequest(OfflineBookingRequest request, String maNV) throws Exception {
        if (request == null) {
            throw new Exception("Booking request không được null");
        }
        
        if (maNV == null || maNV.trim().isEmpty()) {
            throw new Exception("Mã nhân viên không được để trống");
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
        
        if (request.getPhuongThucTT() == null || request.getPhuongThucTT().trim().isEmpty()) {
            throw new Exception("Phương thức thanh toán không được để trống");
        }
        
        // Validate thông tin người đặt vé
        if (request.getNguoiDatHoTen() == null || request.getNguoiDatHoTen().trim().isEmpty()) {
            throw new Exception("Họ tên người đặt vé không được để trống");
        }
        
        if (request.getNguoiDatCMND() == null || request.getNguoiDatCMND().trim().isEmpty()) {
            throw new Exception("CMND/CCCD người đặt vé không được để trống");
        }
        
        // Validate CMND format
        String cmnd = request.getNguoiDatCMND().trim();
        if (!cmnd.matches("\\d{9,12}")) {
            throw new Exception("CMND/CCCD người đặt không hợp lệ (chỉ nhập số, 9-12 ký tự)");
        }
        
        if (request.getDanhSachVe() == null || request.getDanhSachVe().isEmpty()) {
            throw new Exception("Danh sách vé không được để trống");
        }
        
        // Validate từng vé
        for (int i = 0; i < request.getDanhSachVe().size(); i++) {
            BookingTicket ticket = request.getDanhSachVe().get(i);
            validateTicket(ticket, i);
        }

        // Validate CMND không trùng lặp
        validateUniqueCMND(request.getDanhSachVe());
    }

    /**
     * Convert danh sách vé offline sang JSON
     */
    private String convertOfflineTicketsToJson(OfflineBookingRequest request) throws Exception {
        try {
            return mapper.writeValueAsString(request.getDanhSachVe());
        } catch (Exception ex) {
            throw new Exception("Lỗi khi chuyển đổi danh sách vé sang JSON: " + ex.getMessage());
        }
    }
}