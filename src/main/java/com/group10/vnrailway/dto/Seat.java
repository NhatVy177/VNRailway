package com.group10.vnrailway.dto;

import java.math.BigDecimal;

/**
 * Train Seat (Ghế ngồi)
 * Used in seat selection interface
 */
public class Seat {
    
    private String seatId;        // MaCho (MaGhe)
    private Integer row;          // Hang
    private Integer column;       // Cot
    private Integer seatNumber;   // ★ SỐ GHẾ TỰ ĐỘNG: 1, 2, 3...56
    private Boolean available;    // ConTrong (1 = available, 0 = occupied)
    private BigDecimal price;     // GiaVe (calculated on demand)
    
    // Constructors
    public Seat() {
    }
    
    public Seat(String seatId, Integer row, Integer column, Boolean available) {
        this.seatId = seatId;
        this.row = row;
        this.column = column;
        this.available = available;
    }
    
    public Seat(String seatId, Integer row, Integer column, Boolean available, BigDecimal price) {
        this.seatId = seatId;
        this.row = row;
        this.column = column;
        this.available = available;
        this.price = price;
    }
    
    // Getters and Setters
    public String getSeatId() {
        return seatId;
    }
    
    public void setSeatId(String seatId) {
        this.seatId = seatId;
    }
    
    public Integer getRow() {
        return row;
    }
    
    public void setRow(Integer row) {
        this.row = row;
    }
    
    public Integer getColumn() {
        return column;
    }
    
    public void setColumn(Integer column) {
        this.column = column;
    }
    
    // ★ THÊM GETTER/SETTER CHO SEAT NUMBER
    public Integer getSeatNumber() {
        return seatNumber;
    }
    
    public void setSeatNumber(Integer seatNumber) {
        this.seatNumber = seatNumber;
    }
    
    public Boolean getAvailable() {
        return available;
    }
    
    public void setAvailable(Boolean available) {
        this.available = available;
    }
    
    public BigDecimal getPrice() {
        return price;
    }
    
    public void setPrice(BigDecimal price) {
        this.price = price;
    }
    
    // Helper Methods
    public boolean isAvailable() {
        return Boolean.TRUE.equals(available);
    }
    
    public String getStatusClass() {
        return isAvailable() ? "seat-available" : "seat-occupied";
    }
    
    public String getSeatLabel() {
        return row + "-" + column;
    }
    
    public String getFormattedPrice() {
        if (price == null) return "N/A";
        return String.format("%,.0f VNĐ", price);
    }
}