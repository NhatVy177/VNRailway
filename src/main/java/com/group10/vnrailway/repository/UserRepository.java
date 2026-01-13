package com.group10.vnrailway.repository;

import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.group10.vnrailway.entity.User;

import lombok.RequiredArgsConstructor;

@Repository
@RequiredArgsConstructor
public class UserRepository {

    private final JdbcTemplate jdbcTemplate;

    private static final RowMapper<User> USER_ROW_MAPPER = (rs, rowNum) -> new User(
            rs.getString("MaNguoiDung"),
            rs.getString("HoTen"),
            rs.getString("CMND"),
            rs.getDate("NgSinh") != null ? rs.getDate("NgSinh").toLocalDate() : null,
            rs.getString("DiaChi"),
            rs.getString("SDT"),
            rs.getString("LoaiND")
    );

    public Optional<User> findById(String userId) {
        String sql = """
            SELECT * FROM NGUOI_DUNG
            WHERE MaNguoiDung = ?
        """;

        return jdbcTemplate.query(sql, USER_ROW_MAPPER, userId)
                .stream()
                .findFirst();
    }

    public Optional<User> findByPhone(String phone) {
        String sql = """
            SELECT * FROM NGUOI_DUNG
            WHERE SDT = ?
        """;

        return jdbcTemplate.query(sql, USER_ROW_MAPPER, phone)
                .stream()
                .findFirst();
    }
}
