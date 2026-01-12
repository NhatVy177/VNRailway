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
@Table("TAI_KHOAN")
public class Account {

    @Id
    @Column("MaTaiKhoan")
    private String id;

    @Column("MatKhau")
    private String password;

    @Column("NgayDK")
    private LocalDate registerDate;

    @Column("MaUser")
    private String userId;
}
