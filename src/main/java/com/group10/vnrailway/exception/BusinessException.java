package com.group10.vnrailway.exception;

import lombok.Getter;

@Getter
public class BusinessException extends RuntimeException {

    private final String title;

    public BusinessException(String title, String message) {
        super(message);
        this.title = title;
    }
}

