package com.group10.vnrailway.dto;

import java.math.BigDecimal;

/**
 * Train Berth (Giường nằm)
 * Used in berth selection interface for sleeper carriages
 */
public class Berth {
    
    private String berthId;       // MaCho (MaGiuong)
    private Integer roomNumber;   // SoPhong
    private String tier;          // Tang (Tầng 1, Tầng 2, Tầng 3)
    private String side;          // Phia (Trái, Phải, Giữa trái, Giữa phải)
    private Integer berthNumber;  // ★ SỐ THỨ TỰ GIƯỜNG: 1, 2, 3...42
    private Boolean available;    // ConTrong (1 = available, 0 = occupied)
    private BigDecimal price;     // GiaVe (calculated on demand)
    
    // Constructors
    public Berth() {
    }
    
    public Berth(String berthId, Integer roomNumber, String tier, String side, Boolean available) {
        this.berthId = berthId;
        this.roomNumber = roomNumber;
        this.tier = tier;
        this.side = side;
        this.available = available;
    }
    
    public Berth(String berthId, Integer roomNumber, String tier, String side, 
                   Boolean available, BigDecimal price) {
        this.berthId = berthId;
        this.roomNumber = roomNumber;
        this.tier = tier;
        this.side = side;
        this.available = available;
        this.price = price;
    }
    
    // Getters and Setters
    public String getBerthId() {
        return berthId;
    }
    
    public void setBerthId(String berthId) {
        this.berthId = berthId;
    }
    
    public Integer getRoomNumber() {
        return roomNumber;
    }
    
    public void setRoomNumber(Integer roomNumber) {
        this.roomNumber = roomNumber;
    }
    
    public String getTier() {
        return tier;
    }
    
    public void setTier(String tier) {
        this.tier = tier;
    }
    
    public String getSide() {
        return side;
    }
    
    public void setSide(String side) {
        this.side = side;
    }
    
    // ★ GETTER/SETTER CHO BERTH NUMBER
    public Integer getBerthNumber() {
        return berthNumber;
    }
    
    public void setBerthNumber(Integer berthNumber) {
        this.berthNumber = berthNumber;
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
    
    public Integer getTierNumber() {
        if (tier == null) return null;
        // Extract number from "Tầng 1", "Tầng 2", etc.
        try {
            return Integer.parseInt(tier.replaceAll("\\D+", ""));
        } catch (NumberFormatException e) {
            return null;
        }
    }
    
    public String getStatusClass() {
        return isAvailable() ? "berth-available" : "berth-occupied";
    }
    
    public String getTierClass() {
        Integer tierNum = getTierNumber();
        if (tierNum == null) return "";
        return "berth-tier-" + tierNum;
    }
    
    public String getBerthLabel() {
        return "P" + roomNumber + "-" + tier + "-" + side;
    }
    
    public String getFormattedPrice() {
        if (price == null) return "N/A";
        return String.format("%,.0f VNĐ", price);
    }
    
    public boolean isLowerTier() {
        Integer tierNum = getTierNumber();
        return tierNum != null && tierNum == 1;
    }
    
    public boolean isMiddleTier() {
        Integer tierNum = getTierNumber();
        return tierNum != null && tierNum == 2;
    }
    
    public boolean isUpperTier() {
        Integer tierNum = getTierNumber();
        return tierNum != null && tierNum == 3;
    }
}