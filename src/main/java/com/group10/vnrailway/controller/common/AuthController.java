package com.group10.vnrailway.controller.common;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import jakarta.servlet.http.HttpServletRequest;

@Controller
public class AuthController {

  @GetMapping("/register")
  public String getRegister(Model model) {
      return "pages/common/auth/register";
  }

  @GetMapping("/login")
  public String getLogin(
          HttpServletRequest request,
          Model model,
          @RequestParam(required = false) String error
  ) {
      if (error != null) {
          Object msg = request.getSession()
                  .getAttribute("LOGIN_ERROR");

          model.addAttribute("error", msg);
          request.getSession().removeAttribute("LOGIN_ERROR");
      }

      return "pages/common/auth/login";
  }

  @GetMapping("/employee-login")
  public String getEmployeeLogin(
          HttpServletRequest request,
          Model model,
          @RequestParam(required = false) String error
  ) {
      if (error != null) {
          Object msg = request.getSession()
                  .getAttribute("LOGIN_ERROR");

          model.addAttribute("error", msg);
          request.getSession().removeAttribute("LOGIN_ERROR");
      }

      return "pages/common/auth/employee-login";
  }
}
