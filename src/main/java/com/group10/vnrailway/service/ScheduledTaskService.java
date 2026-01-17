package com.group10.vnrailway.service;

import com.group10.vnrailway.repository.ScheduledTaskRepository;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Service xử lý các tác vụ định kỳ (Scheduled Tasks)
 */
@Service
public class ScheduledTaskService {

    private final ScheduledTaskRepository scheduledTaskRepository;

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public ScheduledTaskService(ScheduledTaskRepository scheduledTaskRepository) {
        this.scheduledTaskRepository = scheduledTaskRepository;
    }


    @Scheduled(cron = "0 */5 * * * *")
    public void autoCancelOverdueTickets() {

        String currentTime = LocalDateTime.now().format(FORMATTER);

        System.out.println("========================================");
        System.out.println("🔄 SCHEDULED TASK: Auto Cancel Overdue Tickets");
        System.out.println("⏰ Execution Time: " + currentTime);
        System.out.println("========================================");

        try {
            // Gọi stored procedure
            int affectedRows = scheduledTaskRepository.autoCancelOverdueTickets();

            if (affectedRows > 0) {
                System.out.println("✅ sp_TuDongHuyVeQuaHan executed successfully");
                System.out.println("📌 Affected rows: " + affectedRows);
            } else {
                System.out.println("⚠️ sp_TuDongHuyVeQuaHan executed but no rows affected");
            }

        } catch (Exception ex) {
            System.err.println("❌ ERROR while executing scheduled task");
            System.err.println("Message: " + ex.getMessage());
            ex.printStackTrace();
        }

        System.out.println("========================================\n");
    }
}
