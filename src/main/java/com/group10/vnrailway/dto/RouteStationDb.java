package com.group10.vnrailway.dto;

import java.math.BigDecimal;
import java.time.LocalTime;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class RouteStationDb {
    private String stationId;
    private String stationName;
    private int order;
    private LocalTime travelTime;
    private BigDecimal distance;
}