package com.group10.vnrailway.repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.group10.vnrailway.dto.EmployeeSalaryInfo;
import com.group10.vnrailway.entity.ChinhSachLuong;
import com.group10.vnrailway.entity.Employee;

import lombok.RequiredArgsConstructor;

@Repository
@RequiredArgsConstructor
public class EmployeeRepository {

    private final JdbcTemplate jdbcTemplate;

    private static final RowMapper<Employee> EMPLOYEE_ROW_MAPPER = (rs, rowNum) -> new Employee(
            rs.getString("MaNV"),
            rs.getString("GioiTinh"),
            rs.getString("ChucVu"),
            rs.getString("MaNVQL")
    );

    private static final RowMapper<ChinhSachLuong> CHINH_SACH_LUONG_ROW_MAPPER = (rs, rowNum) -> new ChinhSachLuong(
            rs.getString("MaLoaiNV"),
            rs.getBigDecimal("LuongCoBan"),
            rs.getBigDecimal("PhuCap"),
            rs.getBigDecimal("ThuLaoChuyen"),
            rs.getBigDecimal("ThuLaoThayThe"),
            rs.getBigDecimal("PhatNghiPhep")
    );

    private static final RowMapper<EmployeeSalaryInfo> EMPLOYEE_SALARY_ROW_MAPPER = (rs, rowNum) -> {
        EmployeeSalaryInfo info = new EmployeeSalaryInfo();
        info.setMaNV(rs.getString("MaNV"));
        info.setHoTen(rs.getString("HoTen"));
        info.setSdt(rs.getString("SDT"));
        info.setGioiTinh(rs.getString("GioiTinh"));
        info.setMaLoaiNV(rs.getString("MaLoaiNV"));
        info.setTenLoaiNV(rs.getString("TenLoaiNV"));
        info.setLuongCoBan(rs.getBigDecimal("LuongCoBan"));
        info.setPhuCap(rs.getBigDecimal("PhuCap"));
        info.setThuLaoChuyen(rs.getBigDecimal("ThuLaoChuyen"));
        info.setThuLaoThayThe(rs.getBigDecimal("ThuLaoThayThe"));
        info.setPhatNghiPhep(rs.getBigDecimal("PhatNghiPhep"));
        info.setSoChuyenDaLam(rs.getInt("SoChuyenDaLam"));
        info.setSoChuyenThayThe(rs.getInt("SoChuyenThayThe"));
        info.setSoChuyenNghiPhep(rs.getInt("SoChuyenNghiPhep"));
        info.setTongLuong(rs.getBigDecimal("TongLuong"));
        return info;
    };

    public Optional<Employee> findByUserId(String userId) {
        String sql = """
            SELECT * FROM NHAN_VIEN
            WHERE MaNV = ?
        """;

        return jdbcTemplate.query(sql, EMPLOYEE_ROW_MAPPER, userId)
                .stream()
                .findFirst();
    }

    public List<EmployeeSalaryInfo> getAllEmployeesWithSalary(
            String loaiNV, String timKiem, int page, int pageSize, 
            String sortBy, String sortOrder, Integer thang, Integer nam) {
        String sql = "EXEC sp_LayDanhSachNhanVienVaLuong ?, ?, ?, ?, ?, ?, ?, ?";
        
        return jdbcTemplate.query(sql, EMPLOYEE_SALARY_ROW_MAPPER, 
            page, pageSize, loaiNV, timKiem, sortBy, sortOrder, thang, nam);
    }
    
    public int countEmployees(String loaiNV, String timKiem) {
        String sql = """
            SELECT COUNT(*) 
            FROM NHAN_VIEN nv
            INNER JOIN NGUOI_DUNG nd ON nv.MaNV = nd.MaNguoiDung
            WHERE 
                (? IS NULL OR (
                    CASE 
                        WHEN nv.ChucVu = N'Lái tàu' THEN 'LT'
                        WHEN nv.ChucVu = N'Toa tàu' THEN 'TT'
                        ELSE nv.ChucVu 
                    END
                ) = ?)
                AND (? IS NULL OR 
                     nv.MaNV LIKE '%' + ? + '%' OR 
                     nd.HoTen LIKE '%' + ? + '%' OR
                     nd.SDT LIKE '%' + ? + '%')
        """;
        
        Integer count = jdbcTemplate.queryForObject(sql, Integer.class, 
            loaiNV, loaiNV, timKiem, timKiem, timKiem, timKiem);
        return count != null ? count : 0;
    }

    public Optional<EmployeeSalaryInfo> getEmployeeSalaryById(String maNV, Integer thang, Integer nam) {
        String sql = "EXEC sp_LayThongTinLuongNhanVien ?, ?, ?";
        return jdbcTemplate.query(sql, EMPLOYEE_SALARY_ROW_MAPPER, maNV, thang, nam)
                .stream()
                .findFirst();
    }

    public Optional<ChinhSachLuong> getSalaryPolicyByType(String maLoaiNV) {
        String sql = """
            SELECT * FROM CHINH_SACH_LUONG
            WHERE MaLoaiNV = ?
        """;

        return jdbcTemplate.query(sql, CHINH_SACH_LUONG_ROW_MAPPER, maLoaiNV)
                .stream()
                .findFirst();
    }

    public List<ChinhSachLuong> getAllSalaryPolicies() {
        String sql = "SELECT * FROM CHINH_SACH_LUONG";
        return jdbcTemplate.query(sql, CHINH_SACH_LUONG_ROW_MAPPER);
    }
}
