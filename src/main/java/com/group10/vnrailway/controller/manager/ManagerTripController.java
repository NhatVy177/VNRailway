package com.group10.vnrailway.controller.manager;

import com.group10.vnrailway.request.CreateTripRequest;
import com.group10.vnrailway.service.TripService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequiredArgsConstructor
@RequestMapping("/manager/trips")
public class ManagerTripController {

    private final TripService tripService;

    @GetMapping
    public String getAllTrip(Model model) {
        return "pages/manager/trip/trip-list";
    }


    @GetMapping("/new")
    public String getCreateTrip(Model model,
        @RequestParam(required = false) Long routeId,
        @RequestParam(required = false) Long trainId) {

        model.addAttribute("routeId", "TN01");
        model.addAttribute("routeName", "Hà Nội - Sài Gòn");

        model.addAttribute("trainId", "D030");
        model.addAttribute("trainName", "SE5");

        return "pages/manager/trip/create-trip";
    }


    @PostMapping("/")
    public ResponseEntity<Void> createTrip(
            @ModelAttribute CreateTripRequest request
    ) {
        tripService.createTrip(request);

        return ResponseEntity
                .noContent()
                .header("HX-Redirect", "/manager/trips")
                .build();
    }
}