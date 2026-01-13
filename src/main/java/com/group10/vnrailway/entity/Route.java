package com.group10.vnrailway.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Table("TUYEN")
public class Route {

    @Id
    @Column("MaTuyen")
    private String id;

    @Column("TenTuyen")
    private String name;

    @Column("MaNVQL")
    private String managerId;
}
