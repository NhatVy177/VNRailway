package com.group10.vnrailway.service;

import com.group10.vnrailway.dto.DbOutput;
import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.dto.TripSearchResult;
import com.group10.vnrailway.dto.TripDetail;
import com.group10.vnrailway.dto.Carriage;
import com.group10.vnrailway.exception.BusinessException;
import com.group10.vnrailway.exception.SystemException;
import com.group10.vnrailway.repository.TripRepository;
import com.group10.vnrailway.request.CreateTripRequest;
import com.group10.vnrailway.request.SearchTripRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

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

    public PageResult<TripSearchResult> searchTrips(SearchTripRequest request) {
        // Lấy tất cả kết quả từ DB
        DbOutput<TripSearchResult> output = repository.searchTrips(
                request.getMaGaDi(),
                request.getMaGaDen(),
                request.getNgayDi(),
                request.getGioKhoiHanhTu(),
                request.getGioKhoiHanhDen(),
                request.getLoaiTau(),
                request.getLoaiCho(),
                request.getTrangThai()
        );

        List<TripSearchResult> allTrips = output.getData() != null ? output.getData() : List.of();
        
        // Tính toán pagination
        int page = request.getPage();
        int size = request.getSize();
        int totalElements = allTrips.size();
        int totalPages = (int) Math.ceil((double) totalElements / size);
        
        // Lấy dữ liệu cho trang hiện tại
        int fromIndex = Math.min(request.getOffset(), totalElements);
        int toIndex = Math.min(fromIndex + size, totalElements);
        List<TripSearchResult> pageData = allTrips.subList(fromIndex, toIndex);
        
        // Tạo PageResult
        PageResult<TripSearchResult> pageResult = new PageResult<>();
        pageResult.setData(pageData);
        pageResult.setPage(page);
        pageResult.setSize(size);
        pageResult.setTotalElements(totalElements);
        pageResult.setTotalPages(totalPages);
        
        return pageResult;
    }

    // ============================================================
    // METHODS MỚI CHO TRIP DETAIL & SEAT SELECTION
    // ============================================================

    /**
     * Get complete trip detail with carriages
     */
    public TripDetail getTripDetail(String tripId, String departureStationId, String arrivalStationId) {
        TripDetail tripDetail = repository.getTripDetail(tripId, departureStationId, arrivalStationId);
        
        if (tripDetail == null) {
            throw new IllegalArgumentException("Trip not found with ID: " + tripId);
        }
        
        // Store station info in DTO for later use
        tripDetail.setDepartureStationId(departureStationId);
        tripDetail.setArrivalStationId(arrivalStationId);
        
        return tripDetail;
    }

    /**
     * Get list of carriages for a trip
     */
    public List<Carriage> getCarriages(String tripId, String departureStationId, String arrivalStationId) {
        List<Carriage> carriages = repository.getCarriages(tripId, departureStationId, arrivalStationId);
        
        if (carriages == null || carriages.isEmpty()) {
            throw new IllegalArgumentException("No carriages found for trip: " + tripId);
        }
        
        return carriages;
    }

    /**
     * Get carriage by ID from the list
     */
    public Carriage getCarriageById(String tripId, String carriageId, 
                                       String departureStationId, String arrivalStationId) {
        List<Carriage> carriages = getCarriages(tripId, departureStationId, arrivalStationId);
        
        return carriages.stream()
            .filter(c -> carriageId.equals(c.getCarriageId()))
            .findFirst()
            .orElseThrow(() -> new IllegalArgumentException("Carriage not found: " + carriageId));
    }

    /**
     * Check if trip has available seats
     */
    public boolean hasAvailableSeats(String tripId, String departureStationId, String arrivalStationId) {
        TripDetail tripDetail = getTripDetail(tripId, departureStationId, arrivalStationId);
        return tripDetail.getAvailableSeats() != null && tripDetail.getAvailableSeats() > 0;
    }

    /**
     * Get summary statistics for trip
     */
    public String getTripSummary(String tripId, String departureStationId, String arrivalStationId) {
        TripDetail tripDetail = getTripDetail(tripId, departureStationId, arrivalStationId);
        
        return String.format(
            "Trip %s: %s → %s | %s | Available: %d seats",
            tripDetail.getTripId(),
            departureStationId,
            arrivalStationId,
            tripDetail.getTrainTypeDisplay(),
            tripDetail.getAvailableSeats()
        );
    }
}