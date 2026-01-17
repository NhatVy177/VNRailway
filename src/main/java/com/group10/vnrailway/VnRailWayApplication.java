package com.group10.vnrailway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class VnRailWayApplication {
	public static void main(String[] args) {
		SpringApplication.run(VnRailWayApplication.class, args);
	}
}
