package com.group10.vnrailway.dto;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RouteWithStations {
  private String routeId;
  private String routeName;
  private List<RouteStation> stations;
}