package com.group10.vnrailway.dto;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class PagedDbOutput<T> {

    private final int returnCode;
    private final String message;
    private final List<T> data;
    private final int totalItems;

    public boolean isSuccess() { return returnCode == 0; }
    public boolean isBusinessError() { return returnCode <= -1000 && returnCode >= -1999; }
    public boolean isSystemError() { return returnCode <= -9000 && returnCode >= -9999; }
}
