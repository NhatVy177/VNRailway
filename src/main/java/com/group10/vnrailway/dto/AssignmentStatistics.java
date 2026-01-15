package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO thống kê phân công
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssignmentStatistics {

    private Integer tongSoViTri;
    private Integer soPhanCongDaCo;
    private Integer soNghiPhep;
    private Integer soConThieu;
}
