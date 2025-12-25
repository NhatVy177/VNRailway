package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

/**
 * Wrapper chung cho output của stored procedure
 * @param <T> kiểu dữ liệu trả về (List<T> cho SELECT, null cho INSERT/UPDATE/DELETE)
 */
@Getter
@Setter
@AllArgsConstructor
public class DbOutput<T> {

    private final int returnCode;
    private final String message;
    private final List<T> data;

    public boolean isSuccess() { return returnCode == 0; }
    public boolean isBusinessError() { return returnCode <= -1000 && returnCode >= -1999; }
    public boolean isSystemError() { return returnCode <= -9000 && returnCode >= -9999; }
}
