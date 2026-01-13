package com.group10.vnrailway.controller.common;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import com.group10.vnrailway.security.util.SecurityRedirectUtils;
import com.group10.vnrailway.security.util.SecurityUtils;

@Controller
public class RootController {

    @GetMapping("/")
    public String root() {

        if (SecurityUtils.currentUser() == null) {
            return "redirect:/trips/search";
        }

        return "redirect:" +
                SecurityRedirectUtils.redirectByRole("/trips/search");
    }
}
