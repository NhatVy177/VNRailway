package com.group10.vnrailway.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;

import com.group10.vnrailway.dto.DbOutput;
import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.dto.PagedDbOutput;
import com.group10.vnrailway.dto.TrainHistory;
import com.group10.vnrailway.dto.TrainList;
import com.group10.vnrailway.dto.TripTrain;
import com.group10.vnrailway.entity.Train;
import com.group10.vnrailway.exception.BusinessException;
import com.group10.vnrailway.exception.SystemException;
import com.group10.vnrailway.repository.TrainRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TrainService {

    private final TrainRepository trainRepository;

    @PreAuthorize("hasRole('MANAGER')")
    public PageResult<TripTrain> getTrainsForTrip(
            String routeId,
            LocalDateTime time,
            int page,
            int pageSize
    ) {
        PagedDbOutput<TripTrain> output =
                trainRepository.getTrainsForTrip(routeId, time, page, pageSize);

        if (output.isSuccess()) {
            PageResult<TripTrain> result = new PageResult<>();
            result.setData(output.getData());
            result.setPage(page);
            result.setSize(pageSize);
            result.setTotalElements(output.getTotalItems());
            return result;
        }

        String errorTitle = "Không thể lấy danh sách đoàn tàu cho chuyến.";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }

    // ========== QUẢN LÝ ĐOÀN TÀU ==========

    /**
     * Lấy thông tin đoàn tàu theo ID
     */
    @PreAuthorize("hasRole('MANAGER')")
    public Optional<Train> getTrainById(String id) {
        return trainRepository.getById(id);
    }

    /**
     * Lấy danh sách tất cả đoàn tàu với phân trang
     */
    @PreAuthorize("hasRole('MANAGER')")
    public PageResult<TrainList> getAllTrains(
            String loaiTau,
            String timKiem,
            int page,
            int pageSize
    ) {
        PagedDbOutput<TrainList> output =
                trainRepository.getAllTrains(loaiTau, timKiem, page, pageSize);

        if (output.isSuccess()) {
            PageResult<TrainList> result = new PageResult<>();
            result.setData(output.getData());
            result.setPage(page);
            result.setSize(pageSize);
            result.setTotalElements(output.getTotalItems());
            return result;
        }

        String errorTitle = "Không thể lấy danh sách đoàn tàu.";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }

    /**
     * Thêm đoàn tàu mới
     */
    @PreAuthorize("hasRole('MANAGER')")
    public void createTrain(
            String maDoanTau,
            String tenTau,
            String hangSX,
            LocalDate ngVanHanh,
            String loaiTau
    ) {
        DbOutput<Void> output = trainRepository.createTrain(
                maDoanTau, tenTau, hangSX, ngVanHanh, loaiTau
        );

        if (!output.isSuccess()) {
            String errorTitle = "Không thể thêm đoàn tàu.";
            if (output.isBusinessError()) {
                throw new BusinessException(errorTitle, output.getMessage());
            }
            throw new SystemException(errorTitle);
        }
    }

    /**
     * Cập nhật thông tin đoàn tàu
     */
    @PreAuthorize("hasRole('MANAGER')")
    public void updateTrain(
            String maDoanTau,
            String tenTau,
            String hangSX,
            LocalDate ngVanHanh,
            String loaiTau
    ) {
        DbOutput<Void> output = trainRepository.updateTrain(
                maDoanTau, tenTau, hangSX, ngVanHanh, loaiTau
        );

        if (!output.isSuccess()) {
            String errorTitle = "Không thể cập nhật thông tin đoàn tàu.";
            if (output.isBusinessError()) {
                throw new BusinessException(errorTitle, output.getMessage());
            }
            throw new SystemException(errorTitle);
        }
    }

    /**
     * Lấy lịch sử chuyến tàu của đoàn tàu
     */
    @PreAuthorize("hasRole('MANAGER')")
    public PageResult<TrainHistory> getTrainHistory(
            String maDoanTau,
            LocalDate tuNgay,
            LocalDate denNgay,
            int page,
            int pageSize
    ) {
        PagedDbOutput<TrainHistory> output =
                trainRepository.getTrainHistory(maDoanTau, tuNgay, denNgay, page, pageSize);

        if (output.isSuccess()) {
            PageResult<TrainHistory> result = new PageResult<>();
            result.setData(output.getData());
            result.setPage(page);
            result.setSize(pageSize);
            result.setTotalElements(output.getTotalItems());
            return result;
        }

        String errorTitle = "Không thể lấy lịch sử chuyến tàu.";
        if (output.isBusinessError()) {
            throw new BusinessException(errorTitle, output.getMessage());
        }
        throw new SystemException(errorTitle);
    }
}
