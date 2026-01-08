package com.group10.vnrailway.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Entity đại diện cho bảng GA (Station)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Station {
    private String maGa;      // Station code
    private String tenGa;     // Station name
}