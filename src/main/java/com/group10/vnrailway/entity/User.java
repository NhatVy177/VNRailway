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
@Table("NGUOI_DUNG")
public class User {

    @Id
    @Column("MaNguoiDung")
    private String id;

    @Column("HoTen")
    private String fullName;

    @Column("CMND")
    private String citizenId;

    @Column("NgSinh")
    private LocalDate birthDate;

    @Column("DiaChi")
    private String address;

    @Column("SDT")
    private String phoneNumber;

    @Column("LoaiND")
    private String userType;
}
