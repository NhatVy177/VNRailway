package com.group10.vnrailway.request;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class RouteStationRequest {
    private String stationId;
    private int order;
    private int travelTime;
    private BigDecimal distance;
}