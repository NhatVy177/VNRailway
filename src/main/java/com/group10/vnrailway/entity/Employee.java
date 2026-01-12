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
@Table("NHAN_VIEN")
public class Employee {

    @Id
    @Column("MaNV")
    private String id;

    @Column("GioiTinh")
    private String gender;

    @Column("ChucVu")
    private String position;

    @Column("MaNVQL")
    private String managerId;
}
