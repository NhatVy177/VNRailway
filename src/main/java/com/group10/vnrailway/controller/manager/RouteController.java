package com.group10.vnrailway.controller.manager;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.group10.vnrailway.dto.PageResult;
import com.group10.vnrailway.dto.RouteWithTotalKm;
import com.group10.vnrailway.service.RouteService;

@Controller
@RequestMapping("/manager/routes")
@RequiredArgsConstructor
public class RouteController {

    private final RouteService routeService;

    @GetMapping
    public String getRoutes(
            @RequestParam(defaultValue = "1") int page,
            Model model
    ) {
        PageResult<RouteWithTotalKm> pageResult =
                routeService.getRoutes(page, 10);

        model.addAttribute("pageResult", pageResult);
        return "pages/manager/route/route-list";
    }
}
