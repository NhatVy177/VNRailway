package com.group10.vnrailway.controller.manager;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/manager/statistics")
public class ManagerStatisticsController {

  @GetMapping
  public String getStatistics(Model model) {
      return "pages/manager/statistics/test";
  }
}
