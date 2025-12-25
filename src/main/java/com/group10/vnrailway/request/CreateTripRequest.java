package com.group10.vnrailway.request;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class CreateTripRequest {
    private String routeId;
    private String trainId;
    private LocalDateTime departureTime;
}
