package com.group10.vnrailway.controller.manager;

import lombok.RequiredArgsConstructor;

import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.dto.RouteWithTotalKm;
import com.group10.vnrailway.entity.Station;
import com.group10.vnrailway.service.RouteService;
import com.group10.vnrailway.service.StationService;

@Controller
@RequestMapping("/manager/routes")
@RequiredArgsConstructor
public class ManagerRouteController {

    private final StationService stationService;
    private final RouteService routeService;

    @GetMapping
    public String getRoutes(
            @RequestParam(defaultValue = "1") int page,
            @RequestHeader(value = "HX-Request", required = false) boolean isHtmxRequest,
            Model model
    ) {
        List<Station> stations = stationService.getAllStations();
        PageResult<RouteWithTotalKm> routes = routeService.getRoutes(page, 10);

        model.addAttribute("stations", stations);
        model.addAttribute("routes", routes);

        if (isHtmxRequest) {
            return "pages/manager/route/route-list :: route-list-content";
        }

        return "pages/manager/route/route-list";
    }

    @GetMapping("/select")
    public String getSelectRoute(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(required = false) String returnUrl,
            @RequestHeader(value = "HX-Request", required = false) boolean isHtmxRequest,
            Model model
    ) {
        List<Station> stations = stationService.getAllStations();
        PageResult<RouteWithTotalKm> routes = routeService.getRoutes(page, 10);

        // System.out.println("111111111111111111111");
        // System.out.println(returnUrl);
        
        model.addAttribute("stations", stations);
        model.addAttribute("routes", routes);
        model.addAttribute("returnUrl", returnUrl);
        
        
        if (isHtmxRequest) {
            return "pages/manager/route/select-route :: route-list-content";
        }

        return "pages/manager/route/select-route";
    }
}
