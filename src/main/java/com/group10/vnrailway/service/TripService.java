package com.group10.vnrailway.service;

import com.group10.vnrailway.dto.DbOutput;
import com.group10.vnrailway.exception.BusinessException;
import com.group10.vnrailway.exception.SystemException;
import com.group10.vnrailway.repository.TripRepository;
import com.group10.vnrailway.request.CreateTripRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class TripService {

    private final TripRepository repository;

    public void createTrip(CreateTripRequest request) {
        DbOutput<Void> output = repository.createTrip(
                request.getRouteId(),
                request.getTrainId(),
                request.getDepartureTime()
        );

        if (output.isSuccess()) return;

        String errorTitle = "Không thể thêm chuyến tàu";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }
}
