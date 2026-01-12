package com.group10.vnrailway.controller.admin;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/admin/employees")
public class AdminEmployeeController {

  @GetMapping
  public String getAllEmployees(Model model) {
      return "pages/admin/employee/employee-list";
  }
}
