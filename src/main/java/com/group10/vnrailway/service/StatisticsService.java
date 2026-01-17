package com.group10.vnrailway.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class StatisticsService {

    private final DataSource dataSource;
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    // ========== REVENUE STATISTICS ==========

    /**
     * Thống kê tổng hợp doanh thu
     * SP: sp_ThongKeDoanhThu
     */
    public Map<String, Object> getRevenueSummary(String startDateStr, String endDateStr) {
        Map<String, Object> result = new HashMap<>();
        
        try (Connection conn = dataSource.getConnection();
             CallableStatement stmt = conn.prepareCall("{CALL sp_ThongKeDoanhThu(?, ?, ?)}")) {
            
            // Convert String to Date
            java.sql.Date startDate = java.sql.Date.valueOf(LocalDate.parse(startDateStr, DATE_FORMATTER));
            java.sql.Date endDate = java.sql.Date.valueOf(LocalDate.parse(endDateStr, DATE_FORMATTER));
            
            stmt.setDate(1, startDate);
            stmt.setDate(2, endDate);
            stmt.setString(3, "Tổng thể");
            
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                result.put("totalTickets", rs.getInt("TongSoVe"));
                result.put("totalRevenue", rs.getDouble("TongDoanhThu"));
                result.put("avgRevenue", rs.getDouble("DoanhThuTrungBinhMoiVe"));
                result.put("totalTrips", rs.getInt("SoChuyenTau"));
                result.put("totalCustomers", rs.getInt("SoKhachHang"));
            }
            
        } catch (SQLException e) {
            log.error("Error getting revenue summary", e);
            throw new RuntimeException("Lỗi khi lấy thống kê doanh thu", e);
        }
        
        return result;
    }

    /**
     * Doanh thu theo tháng (cho biểu đồ)
     * SP: sp_ThongKeDoanhThuTheoThang
     */
    public Map<String, Object> getRevenueByMonth(String startDateStr, String endDateStr) {
        Map<String, Object> result = new HashMap<>();
        List<String> labels = new ArrayList<>();
        List<Double> data = new ArrayList<>();
        
        try (Connection conn = dataSource.getConnection()) {
            
            // Parse dates
            LocalDate startDate = LocalDate.parse(startDateStr, DATE_FORMATTER);
            LocalDate endDate = LocalDate.parse(endDateStr, DATE_FORMATTER);
            
            try (CallableStatement stmt = conn.prepareCall("{CALL sp_ThongKeDoanhThuTheoThang(?, ?, ?, ?)}")) {
                stmt.setInt(1, startDate.getMonthValue());
                stmt.setInt(2, startDate.getYear());
                stmt.setInt(3, endDate.getMonthValue());
                stmt.setInt(4, endDate.getYear());
                
                ResultSet rs = stmt.executeQuery();
                while (rs.next()) {
                    int month = rs.getInt("Thang");
                    int year = rs.getInt("Nam");
                    double revenue = rs.getDouble("TongDoanhThu");
                    
                    // Format: "01/2025"
                    labels.add(String.format("%02d/%d", month, year));
                    data.add(revenue);
                }
            }
            
            result.put("labels", labels);
            result.put("data", data);
            
        } catch (SQLException e) {
            log.error("Error getting revenue by month", e);
            throw new RuntimeException("Lỗi khi lấy doanh thu theo tháng", e);
        }
        
        return result;
    }

    /**
     * Số chuyến tàu theo tháng (cho biểu đồ)
     * SP: sp_ThongKeChuyenTauTheoThang
     */
    public Map<String, Object> getTripsByMonth(String startDateStr, String endDateStr) {
        Map<String, Object> result = new HashMap<>();
        List<String> labels = new ArrayList<>();
        List<Integer> data = new ArrayList<>();
        
        try (Connection conn = dataSource.getConnection()) {
            
            LocalDate startDate = LocalDate.parse(startDateStr, DATE_FORMATTER);
            LocalDate endDate = LocalDate.parse(endDateStr, DATE_FORMATTER);
            
            try (CallableStatement stmt = conn.prepareCall("{CALL sp_ThongKeChuyenTauTheoThang(?, ?, ?, ?, ?)}")) {
                stmt.setInt(1, startDate.getMonthValue());
                stmt.setInt(2, startDate.getYear());
                stmt.setInt(3, endDate.getMonthValue());
                stmt.setInt(4, endDate.getYear());
                stmt.setNull(5, Types.NCHAR); // MaTuyen = NULL (all routes)
                
                ResultSet rs = stmt.executeQuery();
                while (rs.next()) {
                    int month = rs.getInt("Thang");
                    int year = rs.getInt("Nam");
                    int trips = rs.getInt("SoChuyen");
                    
                    labels.add(String.format("%02d/%d", month, year));
                    data.add(trips);
                }
            }
            
            result.put("labels", labels);
            result.put("data", data);
            
        } catch (SQLException e) {
            log.error("Error getting trips by month", e);
            throw new RuntimeException("Lỗi khi lấy số chuyến tàu theo tháng", e);
        }
        
        return result;
    }

    /**
     * Doanh thu theo tuyến
     * SP: sp_ThongKeDoanhThuTheoTuyen
     */
    public Map<String, Object> getRevenueByRoute(String startDateStr, String endDateStr) {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> routes = new ArrayList<>();
        
        try (Connection conn = dataSource.getConnection();
             CallableStatement stmt = conn.prepareCall("{CALL sp_ThongKeDoanhThuTheoTuyen(?, ?)}")) {
            
            java.sql.Date startDate = java.sql.Date.valueOf(LocalDate.parse(startDateStr, DATE_FORMATTER));
            java.sql.Date endDate = java.sql.Date.valueOf(LocalDate.parse(endDateStr, DATE_FORMATTER));
            
            stmt.setDate(1, startDate);
            stmt.setDate(2, endDate);
            
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Map<String, Object> route = new HashMap<>();
                route.put("routeId", rs.getString("MaTuyen"));
                route.put("routeName", rs.getString("TenTuyen"));
                route.put("ticketCount", rs.getInt("SoVe"));
                route.put("revenue", rs.getDouble("TongDoanhThu"));
                route.put("percentage", rs.getDouble("TyLePhanTram"));
                routes.add(route);
            }
            
            result.put("routes", routes);
            
        } catch (SQLException e) {
            log.error("Error getting revenue by route", e);
            throw new RuntimeException("Lỗi khi lấy doanh thu theo tuyến", e);
        }
        
        return result;
    }

    /**
     * Doanh thu theo loại chỗ
     * SP: sp_ThongKeDoanhThuTheoLoaiCho
     */
    public Map<String, Object> getRevenueBySeat(String startDateStr, String endDateStr) {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> seats = new ArrayList<>();
        
        try (Connection conn = dataSource.getConnection();
             CallableStatement stmt = conn.prepareCall("{CALL sp_ThongKeDoanhThuTheoLoaiCho(?, ?)}")) {
            
            java.sql.Date startDate = java.sql.Date.valueOf(LocalDate.parse(startDateStr, DATE_FORMATTER));
            java.sql.Date endDate = java.sql.Date.valueOf(LocalDate.parse(endDateStr, DATE_FORMATTER));
            
            stmt.setDate(1, startDate);
            stmt.setDate(2, endDate);
            
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Map<String, Object> seat = new HashMap<>();
                seat.put("seatType", rs.getString("LoaiToa"));
                seat.put("seatTypeName", rs.getString("TenLoaiCho"));
                seat.put("ticketCount", rs.getInt("SoVe"));
                seat.put("revenue", rs.getDouble("TongDoanhThu"));
                seat.put("avgRevenue", rs.getDouble("DoanhThuTrungBinh"));
                seats.add(seat);
            }
            
            result.put("seats", seats);
            
        } catch (SQLException e) {
            log.error("Error getting revenue by seat", e);
            throw new RuntimeException("Lỗi khi lấy doanh thu theo loại chỗ", e);
        }
        
        return result;
    }

    /**
     * Lấy danh sách tuyến đường (cho dropdown)
     * SP: sp_GetDanhSachTuyenDuong
     */
    public Map<String, Object> getRoutes() {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> routes = new ArrayList<>();
        
        try (Connection conn = dataSource.getConnection();
             CallableStatement stmt = conn.prepareCall("{CALL sp_GetDanhSachTuyenDuong}")) {
            
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Map<String, Object> route = new HashMap<>();
                route.put("routeId", rs.getString("MaTuyen"));
                route.put("routeName", rs.getString("TenTuyen"));
                routes.add(route);
            }
            
            result.put("routes", routes);
            
        } catch (SQLException e) {
            log.error("Error getting routes", e);
            throw new RuntimeException("Lỗi khi lấy danh sách tuyến", e);
        }
        
        return result;
    }

    // ========== EMPLOYEE STATISTICS ==========

    /**
     * Thống kê tổng hợp nhân viên theo tháng
     * SP: sp_ThongKeNhanVienTheoThang
     */
    public Map<String, Object> getEmployeeSummary(int month, int year) {
        Map<String, Object> result = new HashMap<>();
        
        try (Connection conn = dataSource.getConnection();
             CallableStatement stmt = conn.prepareCall("{CALL sp_ThongKeNhanVienTheoThang(?, ?)}")) {
            
            stmt.setInt(1, month);
            stmt.setInt(2, year);
            
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                result.put("totalEmployees", rs.getInt("TongNhanVien"));
                result.put("workingEmployees", rs.getInt("NhanVienDiLam"));
                result.put("leaveEmployees", rs.getInt("NhanVienNghiPhep"));
                result.put("unassignedEmployees", rs.getInt("NhanVienKhongPhanCong"));
                
                double absenceRate = rs.getDouble("TyLeVangMat");
                result.put("absenceRate", rs.wasNull() ? 0.0 : absenceRate);
                
                // Calculate total hours (not in SP, need separate calculation or add to SP)
                result.put("totalHours", 0.0); // TODO: Add if needed
            }
            
        } catch (SQLException e) {
            log.error("Error getting employee summary", e);
            throw new RuntimeException("Lỗi khi lấy tổng hợp nhân viên", e);
        }
        
        return result;
    }

    /**
     * Chi tiết thống kê từng nhân viên (có phân trang)
     * SP: sp_ThongKeChiTietNhanVien - Trả về 2 ResultSets
     */
    public Map<String, Object> getEmployeeDetail(int month, int year, int page, int size) {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> employees = new ArrayList<>();
        int totalRecords = 0;
        
        try (Connection conn = dataSource.getConnection();
             CallableStatement stmt = conn.prepareCall("{CALL sp_ThongKeChiTietNhanVien(?, ?, ?, ?)}")) {
            
            stmt.setInt(1, month);
            stmt.setInt(2, year);
            stmt.setInt(3, page);
            stmt.setInt(4, size);
            
            // ResultSet 1: Employee details
            ResultSet rs1 = stmt.executeQuery();
            while (rs1.next()) {
                Map<String, Object> emp = new HashMap<>();
                emp.put("employeeId", rs1.getString("MaNV"));
                emp.put("fullName", rs1.getString("HoTen"));
                emp.put("phone", rs1.getString("SDT"));
                emp.put("department", rs1.getString("BoPhan"));
                emp.put("workHours", rs1.getDouble("SoGioLamViec"));
                emp.put("leaveCount", rs1.getInt("SoLanNghiPhep"));
                employees.add(emp);
            }
            
            // ResultSet 2: Total records
            if (stmt.getMoreResults()) {
                ResultSet rs2 = stmt.getResultSet();
                if (rs2.next()) {
                    totalRecords = rs2.getInt("TotalRecords");
                }
            }
            
            result.put("employees", employees);
            result.put("totalRecords", totalRecords);
            result.put("currentPage", page);
            result.put("pageSize", size);
            result.put("totalPages", (int) Math.ceil((double) totalRecords / size));
            
        } catch (SQLException e) {
            log.error("Error getting employee detail", e);
            throw new RuntimeException("Lỗi khi lấy chi tiết nhân viên", e);
        }
        
        return result;
    }

    /**
     * Thống kê theo bộ phận
     * SP: sp_ThongKeNhanVienTheoBoPhan
     */
    public Map<String, Object> getEmployeeByDepartment(int month, int year) {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> departments = new ArrayList<>();
        
        try (Connection conn = dataSource.getConnection();
             CallableStatement stmt = conn.prepareCall("{CALL sp_ThongKeNhanVienTheoBoPhan(?, ?)}")) {
            
            stmt.setInt(1, month);
            stmt.setInt(2, year);
            
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Map<String, Object> dept = new HashMap<>();
                dept.put("departmentName", rs.getString("BoPhan"));
                dept.put("employeeCount", rs.getInt("SoNhanVien"));
                dept.put("totalHours", rs.getDouble("TongSoGio"));
                dept.put("avgHours", rs.getDouble("TrungBinhGioMoiNguoi"));
                departments.add(dept);
            }
            
            result.put("departments", departments);
            
        } catch (SQLException e) {
            log.error("Error getting employee by department", e);
            throw new RuntimeException("Lỗi khi lấy thống kê theo bộ phận", e);
        }
        
        return result;
    }

    /**
     * Danh sách nhân viên vi phạm
     * SP: sp_ThongKeViPhamNhanVien
     */
    public Map<String, Object> getEmployeeViolation(int month, int year, int threshold) {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> violations = new ArrayList<>();
        
        try (Connection conn = dataSource.getConnection();
             CallableStatement stmt = conn.prepareCall("{CALL sp_ThongKeViPhamNhanVien(?, ?, ?)}")) {
            
            stmt.setInt(1, month);
            stmt.setInt(2, year);
            stmt.setInt(3, threshold);
            
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Map<String, Object> vio = new HashMap<>();
                vio.put("employeeId", rs.getString("MaNV"));
                vio.put("fullName", rs.getString("HoTen"));
                vio.put("phone", rs.getString("SDT"));
                vio.put("department", rs.getString("BoPhan"));
                vio.put("leaveCount", rs.getInt("SoLanNghiPhep"));
                vio.put("workHours", rs.getDouble("SoGioLamViec"));
                violations.add(vio);
            }
            
            result.put("violations", violations);
            
        } catch (SQLException e) {
            log.error("Error getting employee violations", e);
            throw new RuntimeException("Lỗi khi lấy danh sách vi phạm", e);
        }
        
        return result;
    }
}