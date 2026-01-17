package com.group10.vnrailway.util;

import java.time.LocalTime;

public final class TimeUtil {

    private TimeUtil() {}

    public static int convertLocalTimeToMinutes(LocalTime time) {
        if (time == null) {
            return 0;
        }
        return time.getHour() * 60 + time.getMinute();
    }

    public static LocalTime convertMinutesToLocalTime(int minutes) {
        if (minutes < 0) {
            throw new IllegalArgumentException("Số phút phải lớn hơn hoặc bằng 0.");
        }
        int hour = minutes / 60;
        int minute = minutes % 60;
        return LocalTime.of(hour, minute);
    }
}