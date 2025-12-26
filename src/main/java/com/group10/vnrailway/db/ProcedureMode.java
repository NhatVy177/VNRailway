package com.group10.vnrailway.db;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ProcedureMode {
    NORMAL(""),
    ERROR("err"),
    FIX("fix");

    private final String value;

    public boolean isNormal() {
        return value.isEmpty();
    }
}

