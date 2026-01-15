package com.group10.vnrailway.repository;

import com.group10.vnrailway.config.AppConfig;
import com.group10.vnrailway.db.ProcedureNameResolver;
import com.group10.vnrailway.dto.DbOutput;
import com.group10.vnrailway.dto.TripSearchResult;
import com.group10.vnrailway.dto.TripDetail;
import com.group10.vnrailway.dto.Carriage;
import com.group10.vnrailway.dto.TripAssignmentList;
import com.group10.vnrailway.dto.TripAssignmentDetail;
import com.group10.vnrailway.dto.AssignmentStatistics;
import com.group10.vnrailway.dto.EmployeeForAssignment;
import com.group10.vnrailway.dto.AssignmentInfo;
import com.group10.vnrailway.dto.AssignDriverRequest;
import com.group10.vnrailway.dto.AssignAttendantRequest;
import com.group10.vnrailway.dto.ApproveLeaveRequest;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;
import org.springframework.jdbc.core.CallableStatementCallback;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Repository
public class TripRepository {

    private final JdbcTemplate jdbcTemplate;
    private final SimpleJdbcCall createTripCall;
    private final SimpleJdbcCall searchTripCall;

    public TripRepository(JdbcTemplate jdbcTemplate, AppConfig config, ProcedureNameResolver resolver) {
        this.jdbcTemplate = jdbcTemplate;
        
        String spCreateTrip = "usp_ThemChuyenTau";
        String spSearchTrip = "usp_TraCuuChuyenTau";

        if (config.getProblem() == 10) {
            spCreateTrip = resolver.resolve(spCreateTrip);
        }

        this.createTripCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName(spCreateTrip)
                .withReturnValue()
                .declareParameters(
                        new SqlParameter("MaTuyen", Types.NCHAR),
                        new SqlParameter("MaDoanTau", Types.NCHAR),
                        new SqlParameter("ThoiGianXuatPhat", Types.TIMESTAMP),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                );

        this.searchTripCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName(spSearchTrip)
                .withReturnValue()
                .returningResultSet("trips", BeanPropertyRowMapper.newInstance(TripSearchResult.class))
                .declareParameters(
                        new SqlParameter("MaGaDi", Types.NCHAR),
                        new SqlParameter("MaGaDen", Types.NCHAR),
                        new SqlParameter("NgayDi", Types.DATE),
                        new SqlParameter("GioKhoiHanhTu", Types.TIME),
                        new SqlParameter("GioKhoiHanhDen", Types.TIME),
                        new SqlParameter("LoaiTau", Types.NCHAR),
                        new SqlParameter("LoaiCho", Types.NCHAR),
                        new SqlParameter("TrangThai", Types.NCHAR)
                );
    }

    public DbOutput<Void> createTrip(String routeId, String trainId, LocalDateTime departureTime) {
        Map<String, Object> result = createTripCall.execute(Map.of(
                "MaTuyen", routeId,
                "MaDoanTau", trainId,
                "ThoiGianXuatPhat", departureTime
        ));

        int returnCode = result.get("RETURN_VALUE") != null ? (int) result.get("RETURN_VALUE") : -9000;
        String message = (String) result.get("ThongBao");

        return new DbOutput<>(returnCode, message, null);
    }

    @SuppressWarnings("unchecked")
    public DbOutput<TripSearchResult> searchTrips(
            String maGaDi,
            String maGaDen,
            LocalDate ngayDi,
            LocalTime gioKhoiHanhTu,
            LocalTime gioKhoiHanhDen,
            String loaiTau,
            String loaiCho,
            String trangThai) {

        // IMPORTANT: Xử lý empty string thành NULL cho SQL Server
        Map<String, Object> params = new HashMap<>();
        params.put("MaGaDi", isNullOrEmpty(maGaDi) ? null : maGaDi);
        params.put("MaGaDen", isNullOrEmpty(maGaDen) ? null : maGaDen);
        params.put("NgayDi", ngayDi);
        params.put("GioKhoiHanhTu", gioKhoiHanhTu);
        params.put("GioKhoiHanhDen", gioKhoiHanhDen);
        params.put("LoaiTau", isNullOrEmpty(loaiTau) ? null : loaiTau);
        params.put("LoaiCho", isNullOrEmpty(loaiCho) ? null : loaiCho);
        params.put("TrangThai", isNullOrEmpty(trangThai) ? null : trangThai);

        // DEBUG: Log parameters
        System.out.println("=== SEARCH TRIPS PARAMETERS ===");
        params.forEach((key, value) -> 
            System.out.println(key + " = " + (value != null ? value : "NULL"))
        );
        System.out.println("================================");

        try {
            Map<String, Object> result = searchTripCall.execute(params);
            List<TripSearchResult> trips = (List<TripSearchResult>) result.get("trips");
            
            // DEBUG: Log results
            System.out.println("=== SEARCH RESULTS ===");
            System.out.println("Found " + (trips != null ? trips.size() : 0) + " trips");
            System.out.println("======================");

            return new DbOutput<>(0, "Success", trips);
        } catch (Exception e) {
            System.err.println("=== ERROR CALLING STORED PROCEDURE ===");
            e.printStackTrace();
            System.err.println("=======================================");
            throw e;
        }
    }

    /**
     * Helper method: Check if string is null or empty
     */
    private boolean isNullOrEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }

    // ============================================================
    // METHODS MỚI CHO TRIP DETAIL & SEAT SELECTION
    // ============================================================

    /**
     * Get trip detail information
     * Calls: usp_LayChiTietChuyenTau
     */
    public TripDetail getTripDetail(String tripId, String departureStationId, String arrivalStationId) {
        String sql = "EXEC usp_LayChiTietChuyenTau ?, ?, ?";
        
        // ✅ FIX: Dùng query() với varargs thay vì array Object[]
        List<TripDetail> results = jdbcTemplate.query(
            sql,
            new TripDetailRowMapper(),
            tripId, departureStationId, arrivalStationId
        );
        
        return results.isEmpty() ? null : results.get(0);
    }

    /**
     * Get list of carriages for a trip
     * Calls: usp_LayDanhSachToaTheoChuyen
     */
    public List<Carriage> getCarriages(String tripId, String departureStationId, String arrivalStationId) {
        String sql = "EXEC usp_LayDanhSachToaTheoChuyen ?, ?, ?";
        
        // ✅ FIX: Dùng query() với varargs thay vì array Object[]
        return jdbcTemplate.query(
            sql,
            new CarriageRowMapper(),
            tripId, departureStationId, arrivalStationId
        );
    }

    // ============================================================
    // ROW MAPPERS
    // ============================================================

    /**
     * RowMapper for TripDetail
     */
    private static class TripDetailRowMapper implements RowMapper<TripDetail> {
        @Override
        public TripDetail mapRow(ResultSet rs, int rowNum) throws SQLException {
            TripDetail dto = new TripDetail();
            
            dto.setTripId(rs.getString("MaChuyenTau").trim());
            dto.setDepartureTime(rs.getTimestamp("ThoiGianXuatPhat").toLocalDateTime());
            
            if (rs.getTimestamp("ThoiGianDuKienDen") != null) {
                dto.setEstimatedArrivalTime(rs.getTimestamp("ThoiGianDuKienDen").toLocalDateTime());
            }
            
            dto.setTrainId(rs.getString("MaDoanTau").trim());
            dto.setTrainName(rs.getString("TenTau"));
            dto.setTrainType(rs.getString("LoaiTau").trim());
            
            dto.setRouteId(rs.getString("MaTuyen").trim());
            dto.setRouteName(rs.getString("TenTuyen"));
            
            dto.setBookedSeats(rs.getInt("SoChoDaDat"));
            dto.setAvailableSeats(rs.getInt("SoChoConTrong"));
            
            return dto;
        }
    }

    /**
     * RowMapper for Carriage
     */
    private static class CarriageRowMapper implements RowMapper<Carriage> {
        @Override
        public Carriage mapRow(ResultSet rs, int rowNum) throws SQLException {
            return new Carriage(
                rs.getString("MaToa").trim(),
                rs.getInt("STT"),
                rs.getString("LoaiToa").trim(),
                rs.getString("TenLoaiToa"),
                rs.getInt("SoChoTrong")
            );
        }
    }

    // ============================================================
    // MANAGER ASSIGNMENT METHODS
    // ============================================================

    /**
     * Lấy danh sách chuyến tàu cho quản lý phân công
     */
    public DbOutput<TripAssignmentList> getTripsForAssignment(
            String maChuyenTau,
            LocalDate ngayKhoiHanhTu,
            LocalDate ngayKhoiHanhDen,
            String loaiTau,
            String trangThai) {

        String sql = "{CALL usp_LayDanhSachChuyenTauQuanLy(?, ?, ?, ?, ?, ?)}";
        
        try {
            List<TripAssignmentList> trips = jdbcTemplate.query(
                connection -> {
                    var stmt = connection.prepareCall(sql);
                    stmt.setString(1, maChuyenTau);
                    stmt.setObject(2, ngayKhoiHanhTu);
                    stmt.setObject(3, ngayKhoiHanhDen);
                    stmt.setString(4, loaiTau);
                    stmt.setString(5, trangThai);
                    stmt.registerOutParameter(6, Types.NVARCHAR);
                    return stmt;
                },
                (rs, rowNum) -> new TripAssignmentList(
                    rs.getString("MaChuyenTau").trim(),
                    rs.getString("MaTuyen").trim(),
                    rs.getString("TenTuyen"),
                    rs.getString("MaDoanTau").trim(),
                    rs.getString("TenTau"),
                    rs.getString("LoaiTau").trim(),
                    rs.getTimestamp("ThoiGianXuatPhat").toLocalDateTime(),
                    rs.getTimestamp("ThoiGianDuKienDen").toLocalDateTime(),
                    rs.getInt("TongSoViTri"),
                    rs.getInt("SoPhanCongDaCo"),
                    rs.getInt("SoNghiPhep"),
                    rs.getInt("SoConThieu"),
                    rs.getString("TrangThaiPhanCong"),
                    rs.getBoolean("LaChuyenTuongLai")
                )
            );

            return new DbOutput<>(0, "Thành công", trips);
        } catch (Exception e) {
            e.printStackTrace();
            return new DbOutput<>(-9000, "Lỗi hệ thống: " + e.getMessage(), null);
        }
    }

    /**
     * Lấy chi tiết chuyến tàu phân công
     */
    public TripAssignmentDetail getTripAssignmentDetail(String maChuyenTau) {
        String sql = "EXEC usp_LayChiTietChuyenTauPhanCong ?, ?";
        
        List<TripAssignmentDetail> results = jdbcTemplate.query(
            sql,
            (rs, rowNum) -> {
                TripAssignmentDetail dto = new TripAssignmentDetail();
                dto.setMaChuyenTau(rs.getString("MaChuyenTau").trim());
                dto.setMaTuyen(rs.getString("MaTuyen").trim());
                dto.setTenTuyen(rs.getString("TenTuyen"));
                dto.setMaDoanTau(rs.getString("MaDoanTau").trim());
                dto.setTenTau(rs.getString("TenTau"));
                dto.setLoaiTau(rs.getString("LoaiTau").trim());
                dto.setThoiGianXuatPhat(rs.getTimestamp("ThoiGianXuatPhat").toLocalDateTime());
                dto.setThoiGianDuKienDen(rs.getTimestamp("ThoiGianDuKienDen").toLocalDateTime());
                dto.setThoiGianMoBanVe(rs.getTimestamp("ThoiGianMoBanVe").toLocalDateTime());
                dto.setThoiGianDongBanVe(rs.getTimestamp("ThoiGianDongBanVe").toLocalDateTime());
                dto.setSoVeDaBan(rs.getInt("SoVeDaBan"));
                dto.setDoanhThu(rs.getLong("DoanhThu"));
                dto.setLaChuyenTuongLai(dto.getThoiGianXuatPhat().isAfter(LocalDateTime.now()));
                return dto;
            },
            maChuyenTau, ""
        );

        return results.isEmpty() ? null : results.get(0);
    }

    /**
     * Lấy thống kê phân công
     */
    public AssignmentStatistics getAssignmentStatistics(String maChuyenTau) {
        String sql = "EXEC usp_LayThongKePhanCongTheoChuyen ?, ?";
        
        List<AssignmentStatistics> results = jdbcTemplate.query(
            sql,
            (rs, rowNum) -> new AssignmentStatistics(
                rs.getInt("TongSoViTri"),
                rs.getInt("SoPhanCongDaCo"),
                rs.getInt("SoNghiPhep"),
                rs.getInt("SoConThieu")
            ),
            maChuyenTau, ""
        );

        return results.isEmpty() ? null : results.get(0);
    }

    /**
     * Lấy danh sách nhân viên có thể phân công
     */
    public List<EmployeeForAssignment> getEmployeesForAssignment(
            String maChuyenTau, 
            String loaiNhanVien) {
        
        String sql = "{CALL usp_LayDanhSachNhanVienVoiGioLamViec(?, ?, ?)}";
        
        try {
            return jdbcTemplate.query(
                connection -> {
                    var stmt = connection.prepareCall(sql);
                    stmt.setString(1, maChuyenTau);
                    stmt.setString(2, loaiNhanVien);
                    stmt.registerOutParameter(3, Types.NVARCHAR);
                    return stmt;
                },
                (rs, rowNum) -> new EmployeeForAssignment(
                    rs.getString("MaNV").trim(),
                    rs.getString("HoTen"),
                    rs.getString("SDT") != null ? rs.getString("SDT").trim() : null,
                    rs.getString("ChucVu").trim(),
                    rs.getDouble("SoGioLamViecTrongTuan")
                )
            );
        } catch (Exception e) {
            System.err.println("Error getting employees for assignment: " + e.getMessage());
            e.printStackTrace();
            return List.of();
        }
    }

    /**
     * Lấy danh sách phân công hiện tại của chuyến
     * Returns list combining both driver and attendant assignments
     */
    public List<AssignmentInfo> getCurrentAssignments(String maChuyenTau) {
        
        String sql = "{CALL usp_LayDanhSachPhanCongTheoChuyen(?, ?)}";
        
        try {
            List<AssignmentInfo> allAssignments = new ArrayList<>();
            
            jdbcTemplate.execute(
                (org.springframework.jdbc.core.ConnectionCallback<Void>) connection -> {
                    try (CallableStatement cs = connection.prepareCall(sql)) {
                        cs.setString(1, maChuyenTau);
                        cs.registerOutParameter(2, Types.NVARCHAR);
                        
                        boolean hasResults = cs.execute();
                        
                        // Stored procedure mới trả về 1 result set duy nhất (merged)
                        // Columns: STT, VaiTro, MaNV, TenNhanVien, TrangThai, MaToa, LoaiPhanCong
                        if (hasResults) {
                            try (ResultSet rs = cs.getResultSet()) {
                                while (rs.next()) {
                                    allAssignments.add(new AssignmentInfo(
                                        rs.getInt("STT"),
                                        rs.getString("VaiTro"),
                                        rs.getString("MaNV") != null ? rs.getString("MaNV").trim() : null,
                                        rs.getString("TenNhanVien"),
                                        rs.getString("TrangThai"),
                                        null, // ThoiGianLamViec không còn được trả về
                                        rs.getString("MaToa") != null ? rs.getString("MaToa").trim() : null,
                                        rs.getString("LoaiPhanCong")
                                    ));
                                }
                            }
                        }
                        
                        return null;
                    }
                }
            );
            
            return allAssignments;
            
        } catch (Exception e) {
            System.err.println("Error getting current assignments: " + e.getMessage());
            e.printStackTrace();
            return List.of();
        }
    }

    /**
     * Phân công lái tàu
     */
    public DbOutput<Void> assignDriver(AssignDriverRequest request) {
        
        String sql = "{CALL usp_PhanCongLaiTau(?, ?, ?, ?, ?)}";
        
        try {
            String message = jdbcTemplate.execute(
                (org.springframework.jdbc.core.ConnectionCallback<String>) connection -> {
                    try (CallableStatement cs = connection.prepareCall(sql)) {
                        cs.setString(1, request.getMaChuyenTau());
                        cs.setString(2, request.getVaiTro());
                        cs.setString(3, request.getMaNhanVien());
                        cs.setString(4, request.getMaNVQL());
                        cs.registerOutParameter(5, Types.NVARCHAR);
                        
                        cs.execute();
                        return cs.getString(5);
                    }
                }
            );
            
            return new DbOutput<>(0, message, null);
            
        } catch (Exception e) {
            return new DbOutput<>(-9000, "Lỗi: " + e.getMessage(), null);
        }
    }

    /**
     * Phân công nhân viên toa tàu
     */
    public DbOutput<Void> assignAttendant(AssignAttendantRequest request) {
        
        String sql = "{CALL usp_PhanCongToaTau(?, ?, ?, ?, ?, ?)}";
        
        try {
            Map<String, Object> result = jdbcTemplate.execute(
                (org.springframework.jdbc.core.ConnectionCallback<Map<String, Object>>) connection -> {
                    CallableStatement cs = connection.prepareCall(sql);
                    cs.setString(1, request.getMaChuyenTau());
                    cs.setString(2, request.getVaiTro());
                    cs.setString(3, request.getMaToa());
                    cs.setString(4, request.getMaNhanVien());
                    cs.setString(5, request.getMaNVQL());
                    cs.registerOutParameter(6, Types.NVARCHAR);
                    
                    cs.execute();
                    
                    Map<String, Object> output = new HashMap<>();
                    output.put("ThongBao", cs.getString(6));
                    cs.close();
                    return output;
                }
            );
            
            String message = (String) result.get("ThongBao");
            return new DbOutput<>(0, message, null);
            
        } catch (Exception e) {
            return new DbOutput<>(-9000, "Lỗi: " + e.getMessage(), null);
        }
    }

    /**
     * Duyệt nghỉ phép và phân công người thay thế
     */
    public DbOutput<Void> approveLeaveAndAssignReplacement(ApproveLeaveRequest request) {
        
        String sql = "{CALL usp_DuyetNghiPhepVaPhanCongNguoiThay(?, ?, ?, ?, ?)}";
        
        try {
            Map<String, Object> result = jdbcTemplate.execute(
                (org.springframework.jdbc.core.ConnectionCallback<Map<String, Object>>) connection -> {
                    CallableStatement cs = connection.prepareCall(sql);
                    cs.setString(1, request.getMaChuyenTau());
                    cs.setString(2, request.getMaNhanVienNghiPhep());
                    cs.setString(3, request.getMaNhanVienThayThe());
                    cs.setString(4, request.getMaNVQL());
                    cs.registerOutParameter(5, Types.NVARCHAR);
                    
                    cs.execute();
                    
                    Map<String, Object> output = new HashMap<>();
                    output.put("ThongBao", cs.getString(5));
                    cs.close();
                    return output;
                }
            );
            
            String message = (String) result.get("ThongBao");
            return new DbOutput<>(0, message, null);
            
        } catch (Exception e) {
            return new DbOutput<>(-9000, "Lỗi: " + e.getMessage(), null);
        }
    }
}