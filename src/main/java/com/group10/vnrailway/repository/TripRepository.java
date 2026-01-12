package com.group10.vnrailway.repository;

import com.group10.vnrailway.config.AppConfig;
import com.group10.vnrailway.db.ProcedureNameResolver;
import com.group10.vnrailway.dto.DbOutput;
import com.group10.vnrailway.dto.TripSearchResult;
import com.group10.vnrailway.dto.TripDetail;
import com.group10.vnrailway.dto.Carriage;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
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
}