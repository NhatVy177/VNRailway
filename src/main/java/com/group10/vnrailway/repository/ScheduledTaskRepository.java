package com.group10.vnrailway.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * Repository để xử lý các tác vụ tự động (scheduled tasks)
 */
@Repository
public class ScheduledTaskRepository {

    private final JdbcTemplate jdbcTemplate;

    public ScheduledTaskRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * Gọi stored procedure tự động hủy vé quá hạn thanh toán
     * 
     * @return Số vé đã bị hủy
     */
    public int autoCancelOverdueTickets() {
        try {
            // Gọi stored procedure
            jdbcTemplate.execute("EXEC sp_TuDongHuyVeQuaHan");
            return 1; // Success
        } catch (Exception e) {
            System.err.println("Error executing sp_TuDongHuyVeQuaHan: " + e.getMessage());
            return 0; // Failure
        }
    }
}
