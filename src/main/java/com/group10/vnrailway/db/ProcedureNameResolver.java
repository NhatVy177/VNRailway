package com.group10.vnrailway.db;

import com.group10.vnrailway.config.AppConfig;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@AllArgsConstructor
public class ProcedureNameResolver {
    private final AppConfig config;

    public String resolve(String baseProcedureName) {
        return switch (config.getMode()) {
            case NORMAL -> baseProcedureName;
            case ERROR  -> baseProcedureName + "_err";
            case FIX    -> baseProcedureName + "_fix";
        };
    }
}
