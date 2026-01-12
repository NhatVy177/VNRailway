package com.group10.vnrailway.repository;

import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.group10.vnrailway.entity.Account;

import lombok.RequiredArgsConstructor;

@Repository
@RequiredArgsConstructor
public class AccountRepository {

    private final JdbcTemplate jdbcTemplate;

    private static final RowMapper<Account> ACCOUNT_ROW_MAPPER = (rs, rowNum) -> new Account(
            rs.getString("MaTaiKhoan"),
            rs.getString("MatKhau"),
            rs.getDate("NgayDK") != null ? rs.getDate("NgayDK").toLocalDate() : null,
            rs.getString("MaUser")
    );

    public Optional<Account> findByPhone(String phone) {
        String sql = """
            SELECT tk.*
            FROM TAI_KHOAN tk
            JOIN NGUOI_DUNG nd ON tk.MaUser = nd.MaNguoiDung
            WHERE nd.SDT = ?
        """;

        return jdbcTemplate.query(sql, ACCOUNT_ROW_MAPPER, phone)
                .stream()
                .findFirst();
    }

    public Optional<Account> findByUserId(String userId) {
        String sql = """
            SELECT * FROM TAI_KHOAN
            WHERE MaUser = ?
        """;

        return jdbcTemplate.query(sql, ACCOUNT_ROW_MAPPER, userId)
                .stream()
                .findFirst();
    }
}
