package com.group10.vnrailway.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Table("CHUYEN_TAU")
public class Trip {

    @Id
    @Column("MaChuyenTau")
    private String id;

    @Column("MaTuyen")
    private String routeId;

    @Column("MaDoanTau")
    private String trainId;

    @Column("ThoiGianXuatPhat")
    private LocalDateTime departureTime;

    @Column("ThoiGianDuKienDen")
    private LocalDateTime estimatedArrivalTime;
}
