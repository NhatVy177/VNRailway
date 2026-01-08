package com.group10.vnrailway.dto;

/**
 * Train Carriage Information
 * Represents a single carriage in a train
 */
public class Carriage {
    
    private String carriageId;      // MaToa
    private Integer sequenceNumber; // STT - Position in train
    private String carriageType;    // LoaiToa: 'GH', 'GI4', 'GI6'
    private String carriageTypeName; // Toa ghế, Toa giường 4 tầng, Toa giường 6 tầng
    private Integer availableSeats;  // SoChoTrong
    
    // Constructors
    public Carriage() {
    }
    
    public Carriage(String carriageId, Integer sequenceNumber, String carriageType, 
                      String carriageTypeName, Integer availableSeats) {
        this.carriageId = carriageId;
        this.sequenceNumber = sequenceNumber;
        this.carriageType = carriageType;
        this.carriageTypeName = carriageTypeName;
        this.availableSeats = availableSeats;
    }
    
    // Getters and Setters
    public String getCarriageId() {
        return carriageId;
    }
    
    public void setCarriageId(String carriageId) {
        this.carriageId = carriageId;
    }
    
    public Integer getSequenceNumber() {
        return sequenceNumber;
    }
    
    public void setSequenceNumber(Integer sequenceNumber) {
        this.sequenceNumber = sequenceNumber;
    }
    
    public String getCarriageType() {
        return carriageType;
    }
    
    public void setCarriageType(String carriageType) {
        this.carriageType = carriageType;
    }
    
    public String getCarriageTypeName() {
        return carriageTypeName;
    }
    
    public void setCarriageTypeName(String carriageTypeName) {
        this.carriageTypeName = carriageTypeName;
    }
    
    public Integer getAvailableSeats() {
        return availableSeats;
    }
    
    public void setAvailableSeats(Integer availableSeats) {
        this.availableSeats = availableSeats;
    }
    
    // Helper Methods
    public boolean isSeatCarriage() {
        return "GH".equals(carriageType);
    }
    
    public boolean isBerthCarriage() {
        return carriageType != null && carriageType.startsWith("GI");
    }
    
    public boolean isFourBerthCarriage() {
        return "GI4".equals(carriageType);
    }
    
    public boolean isSixBerthCarriage() {
        return "GI6".equals(carriageType);
    }
    
    public boolean hasAvailableSeats() {
        return availableSeats != null && availableSeats > 0;
    }
    
    public String getStatusClass() {
        if (availableSeats == null || availableSeats == 0) {
            return "carriage-full";
        } else if (availableSeats < 10) {
            return "carriage-low";
        } else {
            return "carriage-available";
        }
    }
    
    public String getIconClass() {
        if (isSeatCarriage()) {
            return "carriage-icon-seat";
        } else if (isFourBerthCarriage()) {
            return "carriage-icon-berth-4";
        } else {
            return "carriage-icon-berth-6";
        }
    }
}