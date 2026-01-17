package com.group10.vnrailway.controller.manager;

import lombok.RequiredArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.dto.TrainHistory;
import com.group10.vnrailway.dto.TrainList;
import com.group10.vnrailway.dto.TripTrain;
import com.group10.vnrailway.entity.Train;
import com.group10.vnrailway.service.TrainService;

@Controller
@RequiredArgsConstructor
@RequestMapping("/manager/trains")
public class ManagerTrainController {

     private final TrainService trainService;
     private static final int PAGE_SIZE = 10;

    /**
     * Hiển thị danh sách đoàn tàu
     */
    @GetMapping
    public String getTrains(
            @RequestParam(required = false) String loaiTau,
            @RequestParam(required = false) String timKiem,
            @RequestParam(defaultValue = "1") int page,
            Model model
    ) {
        PageResult<TrainList> pageResult = trainService.getAllTrains(
                loaiTau, timKiem, page, PAGE_SIZE
        );

        model.addAttribute("trains", pageResult.getData());
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", pageResult.getTotalPages());
        model.addAttribute("totalElements", pageResult.getTotalElements());
        model.addAttribute("loaiTau", loaiTau);
        model.addAttribute("timKiem", timKiem);

        return "pages/manager/train/train-list";
    }

    /**
     * Hiển thị form thêm đoàn tàu
     */
    @GetMapping("/create")
    public String showCreateForm(Model model) {
        model.addAttribute("train", new Train());
        model.addAttribute("isEdit", false);
        return "pages/manager/train/train-form";
    }

    /**
     * Xử lý thêm đoàn tàu mới
     */
    @PostMapping("/create")
    public String createTrain(
            @RequestParam String maDoanTau,
            @RequestParam String tenTau,
            @RequestParam String hangSX,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate ngVanHanh,
            @RequestParam String loaiTau,
            RedirectAttributes redirectAttributes
    ) {
        try {
            trainService.createTrain(maDoanTau, tenTau, hangSX, ngVanHanh, loaiTau);
            redirectAttributes.addFlashAttribute("successMessage", "Thêm đoàn tàu thành công!");
            return "redirect:/manager/trains";
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/manager/trains/create";
        }
    }

    /**
     * Hiển thị form sửa đoàn tàu
     */
    @GetMapping("/{id}/edit")
    public String showEditForm(@PathVariable String id, Model model) {
        Train train = trainService.getTrainById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy đoàn tàu: " + id));
        
        model.addAttribute("train", train);
        model.addAttribute("isEdit", true);
        return "pages/manager/train/train-form";
    }

    /**
     * Xử lý cập nhật đoàn tàu
     */
    @PostMapping("/{id}/edit")
    public String updateTrain(
            @PathVariable String id,
            @RequestParam String tenTau,
            @RequestParam String hangSX,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate ngVanHanh,
            @RequestParam String loaiTau,
            RedirectAttributes redirectAttributes
    ) {
        try {
            trainService.updateTrain(id, tenTau, hangSX, ngVanHanh, loaiTau);
            redirectAttributes.addFlashAttribute("successMessage", "Cập nhật đoàn tàu thành công!");
            return "redirect:/manager/trains";
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/manager/trains/" + id + "/edit";
        }
    }

    /**
     * Xem lịch sử chuyến tàu của đoàn tàu
     */
    @GetMapping("/{id}/history")
    public String getTrainHistory(
            @PathVariable String id,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate tuNgay,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate denNgay,
            @RequestParam(defaultValue = "1") int page,
            Model model
    ) {
        PageResult<TrainHistory> pageResult = trainService.getTrainHistory(
                id, tuNgay, denNgay, page, PAGE_SIZE
        );

        Train train = trainService.getTrainById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy đoàn tàu: " + id));

        model.addAttribute("train", train);
        model.addAttribute("histories", pageResult.getData());
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", pageResult.getTotalPages());
        model.addAttribute("totalElements", pageResult.getTotalElements());
        model.addAttribute("tuNgay", tuNgay);
        model.addAttribute("denNgay", denNgay);

        return "pages/manager/train/train-history";
    }

    @GetMapping("/add-to-trip")
    public String selectTrainForTrip(
            @RequestParam String routeId,
            @RequestParam LocalDateTime time,
            @RequestParam(defaultValue = "1") int page,
            Model model
    ) {
        PageResult<TripTrain> pageResult =
                trainService.getTrainsForTrip(routeId, time, page, 10);

        model.addAttribute("pageResult", pageResult);
        return "pages/manager/train/add-train-to-trip";
    }
}