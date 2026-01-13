package com.group10.vnrailway.controller.ticketseller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/ticket-seller/trips")
public class TicketSellerTripController {

  @GetMapping("/search")
  public String getSearchTrips(Model model) {
      return "pages/common/trip/search-trip";
  }
}
