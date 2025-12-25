package com.group10.vnrailway.exception;

import lombok.Getter;

@Getter
public class SystemException extends RuntimeException {

    private static final String DEFAULT_MESSAGE =
        "Đã xảy ra lỗi. Vui lòng thử lại sau.";

    private final String title;
    
    public SystemException(String title) {
        super(DEFAULT_MESSAGE);
        this.title = title;
    }

    public SystemException(String title, String message) {
        super(message);
        this.title = title;
    }
}
