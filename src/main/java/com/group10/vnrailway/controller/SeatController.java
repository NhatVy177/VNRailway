package com.group10.vnrailway.controller;

import com.group10.vnrailway.dto.Seat;
import com.group10.vnrailway.dto.Berth;
import com.group10.vnrailway.dto.Carriage;
import com.group10.vnrailway.service.SeatService;
import com.group10.vnrailway.service.TripService;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Controller for Seat/Berth Selection
 * Handles seat carriage and berth carriage views
 */
@Controller
@RequestMapping("/trips/{tripId}/carriages/{carriageId}")
public class SeatController {
    
    private final SeatService seatService;
    private final TripService tripService;
    
    public SeatController(SeatService seatService, TripService tripService) {
        this.seatService = seatService;
        this.tripService = tripService;
    }
    
    /**
     * Display seat selection page (unified for both seats and berths)
     * URL: GET /trips/{tripId}/carriages/{carriageId}?departureStation={id}&arrivalStation={id}
     * THIS IS FOR FULL PAGE VIEW - NOT USED IN SINGLE PAGE VERSION
     */
    @GetMapping
    public String viewSeatSelection(
            @PathVariable String tripId,
            @PathVariable String carriageId,
            @RequestParam("departureStation") String departureStationId,
            @RequestParam("arrivalStation") String arrivalStationId,
            Model model) {
        
        try {
            // Get carriage info
            Carriage carriage = tripService.getCarriageById(
                tripId, carriageId, departureStationId, arrivalStationId
            );
            
            model.addAttribute("carriage", carriage);
            model.addAttribute("tripId", tripId);
            model.addAttribute("departureStationId", departureStationId);
            model.addAttribute("arrivalStationId", arrivalStationId);
            
            // Determine which template to use based on carriage type
            if (carriage.isSeatCarriage()) {
                List<Seat> seats = seatService.getSeatsWithPrices(
                    tripId, carriageId, departureStationId, arrivalStationId
                );
                model.addAttribute("seats", seats);
                model.addAttribute("seatLayout", seatService.getSeatLayout(
                    tripId, carriageId, departureStationId, arrivalStationId
                ));
                return "pages/trip/seat-selection";
                
            } else {
                List<Berth> berths = seatService.getBerthsWithPrices(
                    tripId, carriageId, departureStationId, arrivalStationId
                );
                model.addAttribute("berths", berths);
                model.addAttribute("berthLayout", seatService.getBerthLayout(
                    tripId, carriageId, departureStationId, arrivalStationId
                ));
                return "pages/trip/seat-selection";
            }
            
        } catch (IllegalArgumentException e) {
            model.addAttribute("errorMessage", e.getMessage());
            return "pages/error";
        }
    }
    
    /**
     * AJAX endpoint to get seat grid HTML fragment
     * URL: GET /trips/{tripId}/carriages/{carriageId}/seats?departureStation={id}&arrivalStation={id}
     * Returns: HTML fragment (not full page)
     */
    @GetMapping("/seats")
    public String loadSeatsFragment(
            @PathVariable String tripId,
            @PathVariable String carriageId,
            @RequestParam("departureStation") String departureStationId,
            @RequestParam("arrivalStation") String arrivalStationId,
            Model model) {
        
        try {
            System.out.println("=== LOADING SEATS FRAGMENT ===");
            System.out.println("Trip: " + tripId);
            System.out.println("Carriage: " + carriageId);
            System.out.println("Departure: " + departureStationId);
            System.out.println("Arrival: " + arrivalStationId);
            
            // Get seats with prices
            List<Seat> seats = seatService.getSeatsWithPrices(
                tripId, carriageId, departureStationId, arrivalStationId
            );
            
            // Get seat layout organized by rows
            Map<Integer, List<Seat>> seatLayout = seatService.getSeatLayout(
                tripId, carriageId, departureStationId, arrivalStationId
            );
            
            System.out.println("Found " + seats.size() + " seats");
            System.out.println("Layout has " + seatLayout.size() + " rows");
            
            model.addAttribute("seats", seats);
            model.addAttribute("seatLayout", seatLayout);
            
            // Return fragment (not full page!)
            return "fragments/seat-grid :: seatGrid";
            
        } catch (Exception e) {
            System.err.println("❌ ERROR loading seats: " + e.getMessage());
            e.printStackTrace();
            
            model.addAttribute("errorMessage", e.getMessage());
            return "fragments/error :: errorFragment";
        }
    }
    
    /**
     * AJAX endpoint to get berth grid HTML fragment
     * URL: GET /trips/{tripId}/carriages/{carriageId}/berths?departureStation={id}&arrivalStation={id}
     * Returns: HTML fragment (not full page)
     */
    @GetMapping("/berths")
    public String loadBerthsFragment(
            @PathVariable String tripId,
            @PathVariable String carriageId,
            @RequestParam("departureStation") String departureStationId,
            @RequestParam("arrivalStation") String arrivalStationId,
            Model model) {
        
        try {
            System.out.println("=== LOADING BERTHS FRAGMENT ===");
            System.out.println("Trip: " + tripId);
            System.out.println("Carriage: " + carriageId);
            
            // Get carriage to check type
            Carriage carriage = tripService.getCarriageById(
                tripId, carriageId, departureStationId, arrivalStationId
            );
            
            // Get berths with prices
            List<Berth> berths = seatService.getBerthsWithPrices(
                tripId, carriageId, departureStationId, arrivalStationId
            );
            
            // Get berth layout organized by rooms
            Map<Integer, List<Berth>> berthLayout = seatService.getBerthLayout(
                tripId, carriageId, departureStationId, arrivalStationId
            );
            
            System.out.println("Found " + berths.size() + " berths");
            System.out.println("Layout has " + berthLayout.size() + " rooms");
            System.out.println("Is 6-berth: " + carriage.isSixBerthCarriage());
            
            model.addAttribute("berths", berths);
            model.addAttribute("berthLayout", berthLayout);
            model.addAttribute("isSixBerth", carriage.isSixBerthCarriage());
            
            // Return fragment (not full page!)
            return "fragments/berth-grid :: berthGrid";
            
        } catch (Exception e) {
            System.err.println("❌ ERROR loading berths: " + e.getMessage());
            e.printStackTrace();
            
            model.addAttribute("errorMessage", e.getMessage());
            return "fragments/error :: errorFragment";
        }
    }
    
    /**
     * AJAX endpoint to calculate price for a specific seat/berth
     * URL: POST /trips/{tripId}/carriages/{carriageId}/price
     * Request body: { "seatId": "...", "departureStation": "...", "arrivalStation": "..." }
     */
    @PostMapping("/price")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> calculatePrice(
            @PathVariable String tripId,
            @PathVariable String carriageId,
            @RequestBody Map<String, String> request) {
        
        try {
            String seatId = request.get("seatId");
            String departureStationId = request.get("departureStation");
            String arrivalStationId = request.get("arrivalStation");
            
            BigDecimal price = seatService.calculatePrice(
                tripId, carriageId, seatId, departureStationId, arrivalStationId
            );
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "seatId", seatId,
                "price", price,
                "formattedPrice", String.format("%,.0f VNĐ", price)
            ));
            
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", e.getMessage()
            ));
        }
    }
    
    /**
     * AJAX endpoint to get carriage statistics
     * URL: GET /trips/{tripId}/carriages/{carriageId}/stats?departureStation={id}&arrivalStation={id}
     */
    @GetMapping("/stats")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getCarriageStats(
            @PathVariable String tripId,
            @PathVariable String carriageId,
            @RequestParam("departureStation") String departureStationId,
            @RequestParam("arrivalStation") String arrivalStationId) {
        
        try {
            Map<String, Object> stats = seatService.getCarriageStats(
                tripId, carriageId, departureStationId, arrivalStationId
            );
            
            return ResponseEntity.ok(stats);
            
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", e.getMessage()
            ));
        }
    }
}