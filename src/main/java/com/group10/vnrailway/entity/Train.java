package com.group10.vnrailway.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Table("DOAN_TAU")
public class Train {

    @Id
    @Column("MaDoanTau")
    private String id;

    @Column("TenTau")
    private String name;

    @Column("HangSX")
    private String manufacturer;

    @Column("NgVanHanh")
    private LocalDate operationDate;

    @Column("LoaiTau")
    private String type;
}
