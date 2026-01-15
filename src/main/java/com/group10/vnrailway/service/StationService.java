package com.group10.vnrailway.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;

import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.dto.PagedDbOutput;
import com.group10.vnrailway.dto.RouteWithTotalKm;
import com.group10.vnrailway.entity.Station;
import com.group10.vnrailway.exception.BusinessException;
import com.group10.vnrailway.exception.SystemException;
import com.group10.vnrailway.repository.RouteRepository;
import com.group10.vnrailway.repository.StationRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class StationService {

    private final StationRepository stationRepository;

    public List<Station> getAllStations() {
      List<Station> stations = stationRepository.getAllStations();
      return stations;
    }
}
