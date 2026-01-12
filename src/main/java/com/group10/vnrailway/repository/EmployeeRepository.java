package com.group10.vnrailway.repository;

import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.group10.vnrailway.entity.Employee;

import lombok.RequiredArgsConstructor;

@Repository
@RequiredArgsConstructor
public class EmployeeRepository {

    private final JdbcTemplate jdbcTemplate;

    private static final RowMapper<Employee> EMPLOYEE_ROW_MAPPER = (rs, rowNum) -> new Employee(
            rs.getString("MaNV"),
            rs.getString("GioiTinh"),
            rs.getString("ChucVu"),
            rs.getString("MaNVQL")
    );

    public Optional<Employee> findByUserId(String userId) {
        String sql = """
            SELECT * FROM NHAN_VIEN
            WHERE MaNV = ?
        """;

        return jdbcTemplate.query(sql, EMPLOYEE_ROW_MAPPER, userId)
                .stream()
                .findFirst();
    }
}
