package com.group10.vnrailway.service;

import java.time.LocalDateTime;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;

import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.dto.PagedDbOutput;
import com.group10.vnrailway.dto.RouteWithTotalKm;
import com.group10.vnrailway.exception.BusinessException;
import com.group10.vnrailway.exception.SystemException;
import com.group10.vnrailway.repository.RouteRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class RouteService {

    private final RouteRepository routeRepository;

    @PreAuthorize("hasRole('MANAGER')")
    public PageResult<RouteWithTotalKm> getRoutes(
            int page,
            int pageSize
    ) {
        PagedDbOutput<RouteWithTotalKm> output =
                routeRepository.getAllRoutes(page, pageSize);

        if (output.isSuccess()) {
            PageResult<RouteWithTotalKm> result = new PageResult<>();
            result.setData(output.getData());
            result.setPage(page);
            result.setSize(pageSize);
            result.setTotalElements(output.getTotalItems());
            return result;
        }

        String errorTitle = "Không thể lấy danh sách tuyến.";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }
}
