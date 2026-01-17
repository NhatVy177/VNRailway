package com.group10.vnrailway.service;

import com.group10.vnrailway.dto.MyBookingDTO;
import com.group10.vnrailway.repository.BookingRepository;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * MyBookingsService - Service xử lý logic liên quan đến danh sách vé đã đặt
 */
@Service
public class MyBookingsService {

    private final BookingRepository bookingRepository;

    public MyBookingsService(BookingRepository bookingRepository) {
        this.bookingRepository = bookingRepository;
    }

    /**
     * Lấy danh sách vé đã đặt của khách hàng, nhóm theo đơn đặt vé
     * 
     * @param maKH - Mã khách hàng
     * @return Map với key là mã đơn, value là danh sách vé trong đơn đó
     */
    public Map<String, List<MyBookingDTO>> getDanhSachVeDaDatTheoKhachHang(String maKH) {
        List<MyBookingDTO> allBookings = bookingRepository.getDanhSachVeDaDat(maKH);
        
        // Nhóm các vé theo mã đơn
        return allBookings.stream()
                .collect(Collectors.groupingBy(
                        MyBookingDTO::getMaDon,
                        LinkedHashMap::new,  // Giữ thứ tự
                        Collectors.toList()
                ));
    }
    
    /**
     * Lấy danh sách vé dạng flat (không nhóm)
     * 
     * @param maKH - Mã khách hàng
     * @return Danh sách tất cả vé
     */
    public List<MyBookingDTO> getDanhSachVeDaDat(String maKH) {
        return bookingRepository.getDanhSachVeDaDat(maKH);
    }
    
    /**
     * Lấy danh sách vé theo số điện thoại hoặc CMND người đặt
     * Dành cho nhân viên bán vé tra cứu
     * 
     * @param soDienThoai - Số điện thoại người đặt (optional)
     * @param cmnd - CMND người đặt (optional)
     * @return Map với key là mã đơn, value là danh sách vé trong đơn đó
     */
    public Map<String, List<MyBookingDTO>> getDanhSachVeTheoSoDienThoaiHoacCMND(String soDienThoai, String cmnd) {
        List<MyBookingDTO> allBookings = bookingRepository.getDanhSachVeTheoSoDienThoaiHoacCMND(soDienThoai, cmnd);
        
        // Nhóm các vé theo mã đơn
        return allBookings.stream()
                .collect(Collectors.groupingBy(
                        MyBookingDTO::getMaDon,
                        LinkedHashMap::new,
                        Collectors.toList()
                ));
    }

    /**
     * Xử lý thanh toán đơn đặt vé
     * Cập nhật trạng thái tất cả vé trong đơn thành "Đã thanh toán"
     * 
     * @param maDon - Mã đơn đặt vé
     * @param maKH - Mã khách hàng (để xác thực quyền sở hữu)
     * @return true nếu thanh toán thành công, false nếu thất bại
     */
    public boolean thanhToanDon(String maDon, String maKH) {
        try {
            int rowsUpdated = bookingRepository.capNhatTrangThaiThanhToan(maDon, maKH);
            return rowsUpdated > 0;
        } catch (Exception e) {
            System.err.println("Error in thanhToanDon: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Xử lý thanh toán từng vé riêng lẻ
     * Cập nhật trạng thái vé thành "Đã thanh toán"
     * 
     * @param maVe - Mã vé cần thanh toán
     * @param maKH - Mã khách hàng (để xác thực quyền sở hữu)
     * @return true nếu thanh toán thành công, false nếu thất bại
     */
    public boolean thanhToanVe(String maVe, String maKH) {
        try {
            int rowsUpdated = bookingRepository.capNhatTrangThaiThanhToanVe(maVe, maKH);
            return rowsUpdated > 0;
        } catch (Exception e) {
            System.err.println("Error in thanhToanVe: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
}
