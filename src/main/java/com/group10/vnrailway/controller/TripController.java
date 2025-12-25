package com.group10.vnrailway.controller;

import com.group10.vnrailway.request.CreateTripRequest;
import com.group10.vnrailway.service.TripService;
import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequiredArgsConstructor
@RequestMapping("/trips")
public class TripController {

    private final TripService tripService;

    @GetMapping("/")
    public String getAllTrip(Model model) {
        return "pages/trip/trip-list";
    }

    @GetMapping("/new")
    public String getCreateForm(Model model,
        @RequestParam(required = false) Long routeId,
        @RequestParam(required = false) Long trainId) {

//        if (routeId != null) {
//            model.addAttribute("routeId", routeId);
//            Route route = routeService.getRouteDetail(routeId);
//            model.addAttribute("routeName", route.name);
//        }
//
//        if (trainId != null)
//        {
//            model.addAttribute("trainId", trainId);
//            Train train = routeService.getTrainDetail(trainId);
//            model.addAttribute("trainName", train.name);
//        }

        model.addAttribute("routeId", "TN01");
        model.addAttribute("routeName", "Hà Nội - Sài Gòn");

        model.addAttribute("trainId", "D030");
        model.addAttribute("trainName", "SE5");

        return "pages/trip/create-trip";
    }

    @PostMapping("/")
    public ResponseEntity<Void> createTrip(
            @ModelAttribute CreateTripRequest request
    ) {
        tripService.createTrip(request);

        return ResponseEntity
                .noContent()
                .header("HX-Redirect", "/trips/")
                .build();
    }
}
