package com.group10.vnrailway.controller.manager;

import lombok.RequiredArgsConstructor;

import java.time.LocalDateTime;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.dto.TripTrain;
import com.group10.vnrailway.service.TrainService;

@Controller
@RequiredArgsConstructor
@RequestMapping("/manager/trains")
public class ManagerTrainController {

     private final TrainService trainService;

    @GetMapping
    public String getTrains(Model model) {
        return "pages/manager/train/train-list";
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