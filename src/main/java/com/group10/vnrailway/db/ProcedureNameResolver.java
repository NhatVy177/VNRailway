package com.group10.vnrailway.db;

import com.group10.vnrailway.config.AppConfig;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@AllArgsConstructor
public class ProcedureNameResolver {
    private final AppConfig config;

    public String resolve(String baseProcedureName) {
        if (config.getMode().isNormal()) {
            return baseProcedureName;
        }

        String suffix = baseProcedureName.substring("usp_".length());

        return "usp_" +
            config.getProblem() + "_" +
            config.getMode().getValue() + "_" +
            suffix;

    }
}
