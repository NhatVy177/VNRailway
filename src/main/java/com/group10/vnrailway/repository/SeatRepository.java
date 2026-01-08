package com.group10.vnrailway.repository;

import com.group10.vnrailway.dto.Seat;
import com.group10.vnrailway.dto.Berth;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

/**
 * Repository for Seat/Berth Operations
 * Calls stored procedures: usp_LayGheTrongToa, usp_LayGiuongTrongToa, usp_TinhGiaVe
 * 
 * ✅ FIXED: Không còn deprecated warnings
 * ★ FIXED: Đọc GiaVe từ stored procedure
 */
@Repository
public class SeatRepository {
    
    private final JdbcTemplate jdbcTemplate;
    
    public SeatRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }
    
    /**
     * Get seats in a seat carriage
     * Calls: usp_LayGheTrongToa
     */
    public List<Seat> getSeats(String tripId, String carriageId, 
                                String departureStationId, String arrivalStationId) {
        String sql = "EXEC usp_LayGheTrongToa ?, ?, ?, ?";
        
        return jdbcTemplate.query(
            sql,
            new SeatRowMapper(),
            tripId, carriageId, departureStationId, arrivalStationId
        );
    }
    
    /**
     * Get berths in a berth carriage
     * Calls: usp_LayGiuongTrongToa
     */
    public List<Berth> getBerths(String tripId, String carriageId,
                                  String departureStationId, String arrivalStationId) {
        String sql = "EXEC usp_LayGiuongTrongToa ?, ?, ?, ?";
        
        return jdbcTemplate.query(
            sql,
            new BerthRowMapper(),
            tripId, carriageId, departureStationId, arrivalStationId
        );
    }
    
    /**
     * Calculate price for a specific seat/berth
     * Calls: usp_TinhGiaVe
     */
    public BigDecimal calculatePrice(String tripId, String carriageId, String seatId,
                                      String departureStationId, String arrivalStationId) {
        String sql = "EXEC usp_TinhGiaVe ?, ?, ?, ?, ?";
        
        List<BigDecimal> results = jdbcTemplate.query(
            sql,
            (rs, rowNum) -> rs.getBigDecimal("GiaVe"),
            tripId, carriageId, seatId, departureStationId, arrivalStationId
        );
        
        return results.isEmpty() ? BigDecimal.ZERO : results.get(0);
    }
    
    /**
     * ★ RowMapper for Seat - ĐỌC GIÁ VÉ
     */
    private static class SeatRowMapper implements RowMapper<Seat> {
        @Override
        public Seat mapRow(ResultSet rs, int rowNum) throws SQLException {
            String seatId = rs.getString("MaCho").trim();
            Integer row = rs.getInt("Hang");
            Integer column = rs.getInt("Cot");
            Boolean available = rs.getInt("ConTrong") == 1;
            
            // ★ ĐỌC GIÁ VÉ TỪ STORED PROCEDURE
            BigDecimal price = null;
            try {
                price = rs.getBigDecimal("GiaVe");
            } catch (SQLException e) {
                // Cột GiaVe không tồn tại (backward compatibility)
                price = BigDecimal.ZERO;
            }
            
            return new Seat(seatId, row, column, available, price);
        }
    }
    
    /**
     * RowMapper for Berth
     */
    private static class BerthRowMapper implements RowMapper<Berth> {
        @Override
        public Berth mapRow(ResultSet rs, int rowNum) throws SQLException {
            String berthId = rs.getString("MaCho").trim();
            Integer roomNumber = rs.getInt("SoPhong");
            String tier = rs.getString("Tang");
            String side = rs.getString("Phia");
            Boolean available = rs.getInt("ConTrong") == 1;
            
            // ★ ĐỌC GIÁ VÉ TỪ STORED PROCEDURE
            BigDecimal price = null;
            try {
                price = rs.getBigDecimal("GiaVe");
            } catch (SQLException e) {
                // Cột GiaVe không tồn tại (backward compatibility)
                price = BigDecimal.ZERO;
            }
            
            return new Berth(berthId, roomNumber, tier, side, available, price);
        }
    }
}