package com.group10.vnrailway.service;

import com.group10.vnrailway.dto.Seat;
import com.group10.vnrailway.dto.Berth;
import com.group10.vnrailway.dto.Carriage;
import com.group10.vnrailway.repository.SeatRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.LinkedHashMap;

/**
 * Service for Seat/Berth selection business logic
 */
@Service
public class SeatService {
    
    private final SeatRepository seatRepository;
    private final TripService tripService;
    
    // ★ CONSTANTS - Số cột ghế mỗi hàng
    private static final int SEATS_PER_ROW = 14;
    
    public SeatService(SeatRepository seatRepository, TripService tripService) {
        this.seatRepository = seatRepository;
        this.tripService = tripService;
    }
    
    /**
     * Get seats for a seat carriage
     */
    public List<Seat> getSeats(String tripId, String carriageId,
                                   String departureStationId, String arrivalStationId) {
        // Validate carriage type
        Carriage carriage = tripService.getCarriageById(
            tripId, carriageId, departureStationId, arrivalStationId
        );
        
        if (!carriage.isSeatCarriage()) {
            throw new IllegalArgumentException("Carriage " + carriageId + " is not a seat carriage");
        }
        
        return seatRepository.getSeats(tripId, carriageId, departureStationId, arrivalStationId);
    }
    
    /**
     * Get berths for a berth carriage
     */
    public List<Berth> getBerths(String tripId, String carriageId,
                                    String departureStationId, String arrivalStationId) {
        // Validate carriage type
        Carriage carriage = tripService.getCarriageById(
            tripId, carriageId, departureStationId, arrivalStationId
        );
        
        if (!carriage.isBerthCarriage()) {
            throw new IllegalArgumentException("Carriage " + carriageId + " is not a berth carriage");
        }
        
        return seatRepository.getBerths(tripId, carriageId, departureStationId, arrivalStationId);
    }
    
    /**
     * ★ Get seat layout organized by rows (14 seats per row)
     * LOGIC: Tự động chia ghế thành 14 cột/hàng và đánh số liên tục
     */
    public Map<Integer, List<Seat>> getSeatLayout(String tripId, String carriageId,
                                                      String departureStationId, String arrivalStationId) {
        List<Seat> seats = getSeats(tripId, carriageId, departureStationId, arrivalStationId);
        
        // Sort by row, then by column
        seats.sort((s1, s2) -> {
            int rowCompare = s1.getRow().compareTo(s2.getRow());
            if (rowCompare != 0) return rowCompare;
            return s1.getColumn().compareTo(s2.getColumn());
        });
        
        // ★ TỰ ĐỘNG ĐÁNH SỐ GHẾ: 1, 2, 3...56
        int seatNumber = 1;
        for (Seat seat : seats) {
            seat.setSeatNumber(seatNumber++);
        }
        
        // ★ CHIA THÀNH CÁC HÀNG 14 GHẾ
        Map<Integer, List<Seat>> layout = new LinkedHashMap<>();
        int currentRow = 0;
        
        for (int i = 0; i < seats.size(); i += SEATS_PER_ROW) {
            int endIndex = Math.min(i + SEATS_PER_ROW, seats.size());
            List<Seat> rowSeats = seats.subList(i, endIndex);
            layout.put(currentRow++, rowSeats);
        }
        
        return layout;
    }
    
    /**
     * Get berth layout organized by rooms
     */
    public Map<Integer, List<Berth>> getBerthLayout(String tripId, String carriageId,
                                                        String departureStationId, String arrivalStationId) {
        // ★ GỌI getBerthsWithPrices() để có berthNumber + giá
        List<Berth> berths = getBerthsWithPrices(tripId, carriageId, departureStationId, arrivalStationId);
        
        // Group theo số phòng
        return berths.stream()
            .collect(Collectors.groupingBy(
                Berth::getRoomNumber,
                LinkedHashMap::new,
                Collectors.toList()
            ));
    }
    
    /**
     * Calculate price for a specific seat/berth
     */
    public BigDecimal calculatePrice(String tripId, String carriageId, String seatId,
                                     String departureStationId, String arrivalStationId) {
        return seatRepository.calculatePrice(
            tripId, carriageId, seatId, departureStationId, arrivalStationId
        );
    }
    
    /**
     * Get seats with prices calculated
     * ★ GIÁ ĐÃ ĐƯỢC TÍNH TRONG STORED PROCEDURE, CHỈ CẦN ĐÁNH SỐ GHẾ
     */
    public List<Seat> getSeatsWithPrices(String tripId, String carriageId,
                                             String departureStationId, String arrivalStationId) {
        List<Seat> seats = getSeats(tripId, carriageId, departureStationId, arrivalStationId);
        
        // Sort by row, then by column
        seats.sort((s1, s2) -> {
            int rowCompare = s1.getRow().compareTo(s2.getRow());
            if (rowCompare != 0) return rowCompare;
            return s1.getColumn().compareTo(s2.getColumn());
        });
        
        // ★ TỰ ĐỘNG ĐÁNH SỐ GHẾ
        int seatNumber = 1;
        for (Seat seat : seats) {
            seat.setSeatNumber(seatNumber++);
            
            // ★ GIÁ ĐÃ CÓ SẴN TỪ STORED PROCEDURE, KHÔNG CẦN TÍNH LẠI
            // Chỉ cần verify nếu price = null thì set = 0
            if (seat.getPrice() == null) {
                seat.setPrice(BigDecimal.ZERO);
            }
        }
        
        return seats;
    }
    
    /**
     * Get berths with prices calculated
     * ★ GIÁ ĐÃ ĐƯỢC TÍNH TRONG SP, ĐÁNH SỐ GIƯỜNG THEO THỨ TỰ
     */
    public List<Berth> getBerthsWithPrices(String tripId, String carriageId,
                                               String departureStationId, String arrivalStationId) {
        List<Berth> berths = getBerths(tripId, carriageId, departureStationId, arrivalStationId);
        
        // ★ SẮP XẾP: Phòng → Tầng (1→2→3, từ dưới lên) → Phía
        berths.sort((b1, b2) -> {
            // So sánh theo số phòng
            int roomCompare = b1.getRoomNumber().compareTo(b2.getRoomNumber());
            if (roomCompare != 0) return roomCompare;
            
            // So sánh theo tầng (Tầng 1 → Tầng 2 → Tầng 3, từ dưới lên)
            int tier1 = b1.getTierNumber() != null ? b1.getTierNumber() : 0;
            int tier2 = b2.getTierNumber() != null ? b2.getTierNumber() : 0;
            int tierCompare = Integer.compare(tier1, tier2); // ★ Normal order (không reverse)
            if (tierCompare != 0) return tierCompare;
            
            // So sánh theo phía (Trái trước, Phải sau)
            return b1.getSide().compareTo(b2.getSide());
        });
        
        // ★ TỰ ĐỘNG ĐÁNH SỐ GIƯỜNG: 1, 2, 3...42
        int berthNumber = 1;
        for (Berth berth : berths) {
            berth.setBerthNumber(berthNumber++);
            
            // ★ GIÁ ĐÃ CÓ SẴN TỪ SP
            if (berth.getPrice() == null) {
                berth.setPrice(BigDecimal.ZERO);
            }
        }
        
        return berths;
    }
    
    /**
     * Get statistics for carriage
     */
    public Map<String, Object> getCarriageStats(String tripId, String carriageId,
                                                 String departureStationId, String arrivalStationId) {
        Carriage carriage = tripService.getCarriageById(
            tripId, carriageId, departureStationId, arrivalStationId
        );
        
        int availableCount;
        int totalCount;
        
        if (carriage.isSeatCarriage()) {
            List<Seat> seats = getSeats(tripId, carriageId, departureStationId, arrivalStationId);
            availableCount = (int) seats.stream().filter(Seat::isAvailable).count();
            totalCount = seats.size();
        } else {
            List<Berth> berths = getBerths(tripId, carriageId, departureStationId, arrivalStationId);
            availableCount = (int) berths.stream().filter(Berth::isAvailable).count();
            totalCount = berths.size();
        }
        
        return Map.of(
            "carriageId", carriageId,
            "carriageType", carriage.getCarriageTypeName(),
            "available", availableCount,
            "occupied", totalCount - availableCount,
            "total", totalCount,
            "occupancyRate", totalCount > 0 ? (totalCount - availableCount) * 100.0 / totalCount : 0.0
        );
    }
}