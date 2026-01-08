package com.group10.vnrailway.dto;

import java.time.LocalDateTime;

/**
 * Trip Detail Information
 * Contains overview information about a specific trip
 */
public class TripDetail {
    
    // Trip Information
    private String tripId;
    private LocalDateTime departureTime;
    private LocalDateTime estimatedArrivalTime;
    
    // Train Information
    private String trainId;
    private String trainName;
    private String trainType; // 'S' = Premium, 'T' = Regular
    
    // Route Information
    private String routeId;
    private String routeName;
    
    // Booking Statistics
    private Integer bookedSeats;
    private Integer availableSeats;
    
    // Station Information (for context)
    private String departureStationId;
    private String departureStationName;
    private String arrivalStationId;
    private String arrivalStationName;
    
    // Constructors
    public TripDetail() {
    }
    
    public TripDetail(String tripId, LocalDateTime departureTime, LocalDateTime estimatedArrivalTime,
                        String trainId, String trainName, String trainType,
                        String routeId, String routeName,
                        Integer bookedSeats, Integer availableSeats) {
        this.tripId = tripId;
        this.departureTime = departureTime;
        this.estimatedArrivalTime = estimatedArrivalTime;
        this.trainId = trainId;
        this.trainName = trainName;
        this.trainType = trainType;
        this.routeId = routeId;
        this.routeName = routeName;
        this.bookedSeats = bookedSeats;
        this.availableSeats = availableSeats;
    }
    
    // Getters and Setters
    public String getTripId() {
        return tripId;
    }
    
    public void setTripId(String tripId) {
        this.tripId = tripId;
    }
    
    public LocalDateTime getDepartureTime() {
        return departureTime;
    }
    
    public void setDepartureTime(LocalDateTime departureTime) {
        this.departureTime = departureTime;
    }
    
    public LocalDateTime getEstimatedArrivalTime() {
        return estimatedArrivalTime;
    }
    
    public void setEstimatedArrivalTime(LocalDateTime estimatedArrivalTime) {
        this.estimatedArrivalTime = estimatedArrivalTime;
    }
    
    public String getTrainId() {
        return trainId;
    }
    
    public void setTrainId(String trainId) {
        this.trainId = trainId;
    }
    
    public String getTrainName() {
        return trainName;
    }
    
    public void setTrainName(String trainName) {
        this.trainName = trainName;
    }
    
    public String getTrainType() {
        return trainType;
    }
    
    public void setTrainType(String trainType) {
        this.trainType = trainType;
    }
    
    public String getRouteId() {
        return routeId;
    }
    
    public void setRouteId(String routeId) {
        this.routeId = routeId;
    }
    
    public String getRouteName() {
        return routeName;
    }
    
    public void setRouteName(String routeName) {
        this.routeName = routeName;
    }
    
    public Integer getBookedSeats() {
        return bookedSeats;
    }
    
    public void setBookedSeats(Integer bookedSeats) {
        this.bookedSeats = bookedSeats;
    }
    
    public Integer getAvailableSeats() {
        return availableSeats;
    }
    
    public void setAvailableSeats(Integer availableSeats) {
        this.availableSeats = availableSeats;
    }
    
    public String getDepartureStationId() {
        return departureStationId;
    }
    
    public void setDepartureStationId(String departureStationId) {
        this.departureStationId = departureStationId;
    }
    
    public String getDepartureStationName() {
        return departureStationName;
    }
    
    public void setDepartureStationName(String departureStationName) {
        this.departureStationName = departureStationName;
    }
    
    public String getArrivalStationId() {
        return arrivalStationId;
    }
    
    public void setArrivalStationId(String arrivalStationId) {
        this.arrivalStationId = arrivalStationId;
    }
    
    public String getArrivalStationName() {
        return arrivalStationName;
    }
    
    public void setArrivalStationName(String arrivalStationName) {
        this.arrivalStationName = arrivalStationName;
    }
    
    // Helper Methods
    public boolean isPremiumTrain() {
        return "S".equals(trainType);
    }
    
    public String getTrainTypeDisplay() {
        return isPremiumTrain() ? "Hạng sang" : "Bình thường";
    }
    
    public Integer getTotalSeats() {
        return (bookedSeats != null ? bookedSeats : 0) + (availableSeats != null ? availableSeats : 0);
    }
    
    public Double getOccupancyRate() {
        Integer total = getTotalSeats();
        if (total == 0) return 0.0;
        return (bookedSeats != null ? bookedSeats : 0) * 100.0 / total;
    }
}