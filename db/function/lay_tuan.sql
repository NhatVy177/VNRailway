-- Lấy thời gian bắt đầu và thời gian kết thúc của tuần chứa @ThoiDiem
-- Phục vụ việc tính tổng số km của đoàn tàu/tổng thời gian chạy tàu của nhân viên 
-- lái tàu đã được phân công trong tuần nào đó
CREATE OR ALTER FUNCTION fn_LayTuan
(
    @ThoiDiem datetime
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        DauTuan = DATEADD(
            DAY,
            - (DATEDIFF(DAY, '19000101', @ThoiDiem) % 7),
            CAST(CAST(@ThoiDiem AS date) AS datetime)
        ),
        
        CuoiTuan = DATEADD(
            DAY,
            7,
            DATEADD(
                DAY,
                - (DATEDIFF(DAY, '19000101', @ThoiDiem) % 7),
                CAST(CAST(@ThoiDiem AS date) AS datetime)
            )
        )
);
GO

SELECT * FROM fn_LayTuan('2025-12-15 00:00:00');
SELECT * FROM fn_LayTuan('2025-12-15 03:20:00');
SELECT * FROM fn_LayTuan('2025-12-15 13:45:00');
SELECT * FROM fn_LayTuan('2025-12-15 23:45:00');
SELECT * FROM fn_LayTuan('2025-12-16 23:45:00');
SELECT * FROM fn_LayTuan('2025-12-21 23:50:00');
SELECT * FROM fn_LayTuan('2025-12-22 00:00:00');
SELECT * FROM fn_LayTuan('2025-12-22 00:00:01');
SELECT * FROM fn_LayTuan('2026-01-29 10:00:00');
