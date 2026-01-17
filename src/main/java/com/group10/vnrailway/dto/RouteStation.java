package com.group10.vnrailway.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RouteStation {
    private String stationId;
    private String stationName;
    private int order;
    private int travelTime = 0; 
    private BigDecimal distance = BigDecimal.ZERO;
}