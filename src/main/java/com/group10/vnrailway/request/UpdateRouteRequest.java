package com.group10.vnrailway.request;

import java.util.List;

import lombok.Data;

@Data
public class UpdateRouteRequest {
    private String routeId;
    private String routeName;
    private List<RouteStationRequest> stations;
}