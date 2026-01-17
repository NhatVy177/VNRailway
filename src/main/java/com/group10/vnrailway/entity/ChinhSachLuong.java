package com.group10.vnrailway.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Table("CHINH_SACH_LUONG")
public class ChinhSachLuong {

    @Id
    @Column("MaLoaiNV")
    private String maLoaiNV;

    @Column("LuongCoBan")
    private BigDecimal luongCoBan;

    @Column("PhuCap")
    private BigDecimal phuCap;

    @Column("ThuLaoChuyen")
    private BigDecimal thuLaoChuyen;

    @Column("ThuLaoThayThe")
    private BigDecimal thuLaoThayThe;

    @Column("PhatNghiPhep")
    private BigDecimal phatNghiPhep;
}
