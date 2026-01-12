package com.group10.vnrailway.controller.common;

import com.group10.vnrailway.dto.TripSearchResult;
import com.group10.vnrailway.dto.TripDetail;
import com.group10.vnrailway.dto.Carriage;
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

@Controller
@RequiredArgsConstructor
@RequestMapping("/trips")
public class CommonTripController {

    private final TripService tripService;
    private final StationRepository stationRepository;


    @GetMapping("/search")
    public String getSearchTrip(Model model) {
        // Load station list for dropdown
        List<Station> stations = stationRepository.getAllStations();
        
        model.addAttribute("searchRequest", new SearchTripRequest());
        model.addAttribute("stations", stations);
        
        return "pages/common/trip/search-trip";
    }


    @PostMapping("/search")
    public String searchTrip(
            @ModelAttribute SearchTripRequest request,
            @RequestParam(value = "page", defaultValue = "1") Integer page,
            Model model
    ) {
        // Set page number from request parameter
        request.setPage(page);
        
        PageResult<TripSearchResult> pageResult = tripService.searchTrips(request);

        // Reload station list for form
        List<Station> stations = stationRepository.getAllStations();
        
        model.addAttribute("trips", pageResult.getData());
        model.addAttribute("pageResult", pageResult);
        model.addAttribute("searchRequest", request);
        model.addAttribute("stations", stations);

        return "pages/common/trip/search-trip";
    }


    /**
     * Display trip details with carriage list
     * URL: GET /trips/{tripId}?departureStation={id}&arrivalStation={id}
     * 
     * This endpoint is called when user clicks on a trip card from search results.
     * It displays:
     * - Trip information (departure time, route, train type, etc.)
     * - List of carriages with seat availability
     * - Visual train layout
     * 
     * @param tripId The trip identifier (e.g., "CT001")
     * @param departureStationId The departure station code (e.g., "SG")
     * @param arrivalStationId The arrival station code (e.g., "HN")
     * @param model Spring MVC model for passing data to view
     * @return Template name "pages/trip/trip-detail"
     */
    @GetMapping("/{tripId}")
    public String getTripDetails(
            @PathVariable String tripId,
            @RequestParam("departureStation") String departureStationId,
            @RequestParam("arrivalStation") String arrivalStationId,
            Model model) {
        
        try {
            // Get trip details from service layer
            TripDetail tripDetail = tripService.getTripDetail(
                tripId, 
                departureStationId, 
                arrivalStationId
            );
            
            // Get list of carriages with availability info
            List<Carriage> carriages = tripService.getCarriages(
                tripId, 
                departureStationId, 
                arrivalStationId
            );
            
            // Add attributes to model for Thymeleaf template
            model.addAttribute("tripDetail", tripDetail);
            model.addAttribute("carriages", carriages);
            model.addAttribute("departureStationId", departureStationId);
            model.addAttribute("arrivalStationId", arrivalStationId);
            
            return "pages/common/trip/trip-detail";
            
        } catch (IllegalArgumentException e) {
            // Handle business errors (trip not found, invalid stations, etc.)
            model.addAttribute("errorMessage", e.getMessage());
            model.addAttribute("errorDetails", "Không tìm thấy thông tin chuyến tàu hoặc ga không hợp lệ.");
            return "pages/error";
            
        } catch (Exception e) {
            // Handle system errors
            model.addAttribute("errorMessage", "Lỗi hệ thống");
            model.addAttribute("errorDetails", "Đã xảy ra lỗi khi tải thông tin chuyến tàu. Vui lòng thử lại sau.");
            return "pages/error";
        }
    }
}