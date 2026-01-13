package com.group10.vnrailway.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class RouteWithTotalKm {

    private String id;         
    private String name;        
    private BigDecimal totalKm;
}
