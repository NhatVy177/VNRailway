package com.group10.vnrailway.service;

import java.time.LocalDateTime;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;

import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.dto.PagedDbOutput;
import com.group10.vnrailway.dto.TripTrain;
import com.group10.vnrailway.exception.BusinessException;
import com.group10.vnrailway.exception.SystemException;
import com.group10.vnrailway.repository.TrainRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TrainService {

    private final TrainRepository trainRepository;

    @PreAuthorize("hasRole('MANAGER')")
    public PageResult<TripTrain> getTrainsForTrip(
            String routeId,
            LocalDateTime time,
            int page,
            int pageSize
    ) {
        PagedDbOutput<TripTrain> output =
                trainRepository.getTrainsForTrip(routeId, time, page, pageSize);

        if (output.isSuccess()) {
            PageResult<TripTrain> result = new PageResult<>();
            result.setData(output.getData());
            result.setPage(page);
            result.setSize(pageSize);
            result.setTotalElements(output.getTotalItems());
            return result;
        }

        String errorTitle = "Không thể lấy danh sách đoàn tàu cho chuyến.";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }
}
