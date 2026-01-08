package com.group10.vnrailway.repository;

import com.group10.vnrailway.entity.Station;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for Station (GA) table
 */
@Repository
public class StationRepository {

    private final JdbcTemplate jdbcTemplate;

    public StationRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * Get all stations, sorted by name
     * @return List of all stations
     */
    public List<Station> getAllStations() {
        String sql = "SELECT MaGa, TenGa FROM GA ORDER BY TenGa";
        return jdbcTemplate.query(sql, BeanPropertyRowMapper.newInstance(Station.class));
    }

    /**
     * Search stations by name (for autocomplete)
     * @param keyword Search keyword
     * @return Matching stations
     */
    public List<Station> searchStationsByName(String keyword) {
        String sql = "SELECT MaGa, TenGa FROM GA WHERE TenGa LIKE ? ORDER BY TenGa";
        return jdbcTemplate.query(sql, 
            BeanPropertyRowMapper.newInstance(Station.class),
            "%" + keyword + "%");
    }
}