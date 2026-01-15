package com.group10.vnrailway.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class TripTrain {

    private String id;        
    private String name;    
    private String manufacturer;  
    private LocalDate operationDate;
    private String type;
    private BigDecimal weeklyKm;
}
