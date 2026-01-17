package com.group10.vnrailway.controller.employee;

import com.group10.vnrailway.dto.TripSearchResult;
import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.entity.Station;
import com.group10.vnrailway.repository.StationRepository;
import com.group10.vnrailway.request.SearchTripRequest;
import com.group10.vnrailway.service.TripService;
import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller tra cứu chuyến tàu cho nhân viên bán vé
 */
@Controller
@RequiredArgsConstructor
@RequestMapping("/employee/trips")
public class EmployeeTripController {

    private final TripService tripService;
    private final StationRepository stationRepository;

    /**
     * Hiển thị form tìm kiếm chuyến tàu
     */
    @GetMapping("/search")
    public String getSearchTrip(Model model) {
        // Load station list for dropdown
        List<Station> stations = stationRepository.getAllStations();
        
        model.addAttribute("searchRequest", new SearchTripRequest());
        model.addAttribute("stations", stations);
        
        return "pages/common/trip/search-trip";
    }

    /**
     * Xử lý tìm kiếm chuyến tàu
     */
    @PostMapping("/search")
    public String searchTrip(
            @ModelAttribute SearchTripRequest request,
            @RequestParam(value = "page", defaultValue = "1") Integer page,
            Model model
    ) {
        request.setPage(page);
        
        PageResult<TripSearchResult> pageResult = tripService.searchTrips(request);
        List<Station> stations = stationRepository.getAllStations();
        
        model.addAttribute("searchRequest", request);
        model.addAttribute("stations", stations);
        model.addAttribute("pageResult", pageResult);
        
        return "pages/common/trip/search-trip";
    }
}
