-- Lấy thời điểm bắt đầu và thời điểm kết thúc của tuần chứa @InputDate
-- Phục vụ việc tính tổng số km của đoàn tàu/tổng thời gian chạy tàu của nhân viên 
-- lái tàu đã được phân công trong tuần nào đó
CREATE OR ALTER FUNCTION fn_GetWeekRange
(
    @InputDate datetime
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        StartOfWeek = DATEADD(
            DAY,
            - (DATEDIFF(DAY, '19000101', @InputDate) % 7),
            CAST(CAST(@InputDate AS date) AS datetime)
        ),
        
        EndOfWeek = DATEADD(
            DAY,
            7,
            DATEADD(
                DAY,
                - (DATEDIFF(DAY, '19000101', @InputDate) % 7),
                CAST(CAST(@InputDate AS date) AS datetime)
            )
        )
);
GO

SELECT * FROM fn_GetWeekRange('2025-12-15 00:00:00');
SELECT * FROM fn_GetWeekRange('2025-12-15 03:20:00');
SELECT * FROM fn_GetWeekRange('2025-12-15 13:45:00');
SELECT * FROM fn_GetWeekRange('2025-12-15 23:45:00');
SELECT * FROM fn_GetWeekRange('2025-12-16 23:45:00');
SELECT * FROM fn_GetWeekRange('2025-12-21 23:50:00');
SELECT * FROM fn_GetWeekRange('2025-12-22 00:00:00');
SELECT * FROM fn_GetWeekRange('2025-12-22 00:00:01');
SELECT * FROM fn_GetWeekRange('2026-01-29 10:00:00');
