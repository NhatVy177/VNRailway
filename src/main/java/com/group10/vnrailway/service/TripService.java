package com.group10.vnrailway.service;

import com.group10.vnrailway.dto.DbOutput;
import com.group10.vnrailway.dto.EmployeeForAssignment;
import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.dto.TripSearchResult;
import com.group10.vnrailway.dto.TripDetail;
import com.group10.vnrailway.dto.Carriage;
import com.group10.vnrailway.dto.TripAssignmentList;
import com.group10.vnrailway.dto.TripAssignmentDetail;
import com.group10.vnrailway.dto.ApproveLeaveRequest;
import com.group10.vnrailway.dto.AssignAttendantRequest;
import com.group10.vnrailway.dto.AssignDriverRequest;
import com.group10.vnrailway.dto.AssignmentInfo;
import com.group10.vnrailway.dto.AssignmentStatistics;
import com.group10.vnrailway.exception.BusinessException;
import com.group10.vnrailway.exception.SystemException;
import com.group10.vnrailway.repository.TripRepository;
import com.group10.vnrailway.request.CreateTripRequest;
import com.group10.vnrailway.request.SearchTripRequest;
import lombok.RequiredArgsConstructor;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TripService {

    private final TripRepository tripRepository;

    @PreAuthorize("hasRole('MANAGER')")
    public void createTrip(CreateTripRequest request) {
        DbOutput<Void> output = tripRepository.createTrip(
                request.getRouteId(),
                request.getTrainId(),
                request.getDepartureTime()
        );

        if (output.isSuccess()) return;

        String errorTitle = "Không thể thêm chuyến tàu";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }

    public PageResult<TripSearchResult> searchTrips(SearchTripRequest request) {
        // Lấy tất cả kết quả từ DB
        DbOutput<TripSearchResult> output = tripRepository.searchTrips(
                request.getMaGaDi(),
                request.getMaGaDen(),
                request.getNgayDi(),
                request.getGioKhoiHanhTu(),
                request.getGioKhoiHanhDen(),
                request.getLoaiTau(),
                request.getLoaiCho(),
                request.getTrangThai()
        );

        List<TripSearchResult> allTrips = output.getData() != null ? output.getData() : List.of();
        
        // Tính toán pagination
        int page = request.getPage();
        int size = request.getSize();
        int totalElements = allTrips.size();
        int totalPages = (int) Math.ceil((double) totalElements / size);
        
        // Lấy dữ liệu cho trang hiện tại
        int fromIndex = Math.min(request.getOffset(), totalElements);
        int toIndex = Math.min(fromIndex + size, totalElements);
        List<TripSearchResult> pageData = allTrips.subList(fromIndex, toIndex);
        
        // Tạo PageResult
        PageResult<TripSearchResult> pageResult = new PageResult<>();
        pageResult.setData(pageData);
        pageResult.setPage(page);
        pageResult.setSize(size);
        pageResult.setTotalElements(totalElements);
        pageResult.setTotalPages(totalPages);
        
        return pageResult;
    }

    // ============================================================
    // METHODS MỚI CHO TRIP DETAIL & SEAT SELECTION
    // ============================================================

    /**
     * Get complete trip detail with carriages
     */
    public TripDetail getTripDetail(String tripId, String departureStationId, String arrivalStationId) {
        TripDetail tripDetail = tripRepository.getTripDetail(tripId, departureStationId, arrivalStationId);
        
        if (tripDetail == null) {
            throw new IllegalArgumentException("Trip not found with ID: " + tripId);
        }
        
        // Store station info in DTO for later use
        tripDetail.setDepartureStationId(departureStationId);
        tripDetail.setArrivalStationId(arrivalStationId);
        
        return tripDetail;
    }

    /**
     * Get list of carriages for a trip
     */
    public List<Carriage> getCarriages(String tripId, String departureStationId, String arrivalStationId) {
        List<Carriage> carriages = tripRepository.getCarriages(tripId, departureStationId, arrivalStationId);
        
        if (carriages == null || carriages.isEmpty()) {
            throw new IllegalArgumentException("No carriages found for trip: " + tripId);
        }
        
        return carriages;
    }

    /**
     * Get carriage by ID from the list
     */
    public Carriage getCarriageById(String tripId, String carriageId, 
                                       String departureStationId, String arrivalStationId) {
        List<Carriage> carriages = getCarriages(tripId, departureStationId, arrivalStationId);
        
        return carriages.stream()
            .filter(c -> carriageId.equals(c.getCarriageId()))
            .findFirst()
            .orElseThrow(() -> new IllegalArgumentException("Carriage not found: " + carriageId));
    }

    /**
     * Check if trip has available seats
     */
    public boolean hasAvailableSeats(String tripId, String departureStationId, String arrivalStationId) {
        TripDetail tripDetail = getTripDetail(tripId, departureStationId, arrivalStationId);
        return tripDetail.getAvailableSeats() != null && tripDetail.getAvailableSeats() > 0;
    }

    /**
     * Get summary statistics for trip
     */
    public String getTripSummary(String tripId, String departureStationId, String arrivalStationId) {
        TripDetail tripDetail = getTripDetail(tripId, departureStationId, arrivalStationId);
        
        return String.format(
            "Trip %s: %s → %s | %s | Available: %d seats",
            tripDetail.getTripId(),
            departureStationId,
            arrivalStationId,
            tripDetail.getTrainTypeDisplay(),
            tripDetail.getAvailableSeats()
        );
    }

    // ============================================================
    // MANAGER ASSIGNMENT METHODS
    // ============================================================

    /**
     * Lấy danh sách chuyến tàu cho quản lý phân công (có phân trang)
     */
    @PreAuthorize("hasRole('MANAGER')")
    public PageResult<TripAssignmentList> getTripsForAssignmentPaged(
            String maChuyenTau,
            java.time.LocalDate ngayKhoiHanhTu,
            java.time.LocalDate ngayKhoiHanhDen,
            String loaiTau,
            String trangThai,
            int page,
            int size) {

        // Lấy tất cả kết quả từ method hiện có
        List<TripAssignmentList> allTrips = getTripsForAssignment(
                maChuyenTau, ngayKhoiHanhTu, ngayKhoiHanhDen, loaiTau, trangThai
        );

        // Tính toán pagination
        int totalElements = allTrips.size();
        int totalPages = (int) Math.ceil((double) totalElements / size);

        int fromIndex = Math.min(page * size, totalElements);
        int toIndex = Math.min(fromIndex + size, totalElements);
        List<TripAssignmentList> pageData = allTrips.subList(fromIndex, toIndex);

        // Tạo PageResult
        PageResult<TripAssignmentList> result = new PageResult<>();
        result.setData(pageData);
        result.setPage(page);
        result.setSize(size);
        result.setTotalElements(totalElements);
        result.setTotalPages(totalPages);

        return result;
    }

    /**
     * Lấy danh sách chuyến tàu cho quản lý phân công (không phân trang)
     */
    @PreAuthorize("hasRole('MANAGER')")
    public List<TripAssignmentList> getTripsForAssignment(
            String maChuyenTau,
            java.time.LocalDate ngayKhoiHanhTu,
            java.time.LocalDate ngayKhoiHanhDen,
            String loaiTau,
            String trangThai) {

        DbOutput<TripAssignmentList> output = tripRepository.getTripsForAssignment(
                maChuyenTau, ngayKhoiHanhTu, ngayKhoiHanhDen, loaiTau, trangThai
        );

        if (output.isSuccess()) {
            return output.getData() != null ? output.getData() : List.of();
        }

        String errorTitle = "Không thể lấy danh sách chuyến tàu";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }

    /**
     * Lấy chi tiết chuyến tàu phân công
     */
    @PreAuthorize("hasRole('MANAGER')")
    public TripAssignmentDetail getTripAssignmentDetail(String maChuyenTau) {
        TripAssignmentDetail detail = tripRepository.getTripAssignmentDetail(maChuyenTau);
        
        if (detail == null) {
            throw new BusinessException("Không tìm thấy chuyến tàu", "Chuyến tàu không tồn tại");
        }
        
        return detail;
    }

    /**
     * Lấy thống kê phân công
     */
    @PreAuthorize("hasRole('MANAGER')")
    public AssignmentStatistics getAssignmentStatistics(String maChuyenTau) {
        AssignmentStatistics stats = tripRepository.getAssignmentStatistics(maChuyenTau);
        
        if (stats == null) {
            throw new BusinessException("Không tìm thấy thống kê", "Không thể lấy thông tin phân công");
        }
        
        return stats;
    }

    // ============================================================
    // ASSIGNMENT METHODS
    // ============================================================

    /**
     * Lấy danh sách nhân viên có thể phân công
     */
    @PreAuthorize("hasRole('MANAGER')")
    public List<EmployeeForAssignment> getEmployeesForAssignment(
            String maChuyenTau, 
            String type) {
        
        // Map type từ URL param sang ChucVu trong database
        String loaiNhanVien;
        if ("laitau".equalsIgnoreCase(type)) {
            loaiNhanVien = "LT";
        } else if ("toatau".equalsIgnoreCase(type)) {
            loaiNhanVien = "TT";
        } else {
            throw new BusinessException(
                "Loại nhân viên không hợp lệ",
                "Type phải là 'laitau' hoặc 'toatau'"
            );
        }
        
        return tripRepository.getEmployeesForAssignment(maChuyenTau, loaiNhanVien);
    }

    /**
     * Lấy danh sách phân công hiện tại
     */
    @PreAuthorize("hasRole('MANAGER')")
    public List<AssignmentInfo> getCurrentAssignments(String maChuyenTau) {
        return tripRepository.getCurrentAssignments(maChuyenTau);
    }

    /**
     * Phân công lái tàu
     */
    @PreAuthorize("hasRole('MANAGER')")
    public void assignDriver(AssignDriverRequest request) {
        DbOutput<Void> output = tripRepository.assignDriver(request);
        
        if (output.isSuccess()) return;
        
        String errorTitle = "Không thể phân công lái tàu";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }

    /**
     * Phân công nhân viên toa tàu
     */
    @PreAuthorize("hasRole('MANAGER')")
    public void assignAttendant(AssignAttendantRequest request) {
        DbOutput<Void> output = tripRepository.assignAttendant(request);
        
        if (output.isSuccess()) return;
        
        String errorTitle = "Không thể phân công nhân viên toa tàu";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }

    /**
     * Duyệt nghỉ phép và phân công người thay thế
     */
    @PreAuthorize("hasRole('MANAGER')")
    public void approveLeaveAndAssignReplacement(ApproveLeaveRequest request) {
        DbOutput<Void> output = tripRepository.approveLeaveAndAssignReplacement(request);
        
        if (output.isSuccess()) return;
        
        String errorTitle = "Không thể duyệt nghỉ phép";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }
}