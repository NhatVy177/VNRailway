package com.group10.vnrailway.security.config;

import lombok.RequiredArgsConstructor;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

import com.group10.vnrailway.security.handler.LoginFailureHandler;
import com.group10.vnrailway.security.handler.LoginSuccessHandler;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final LoginSuccessHandler loginSuccessHandler;
    private final LoginFailureHandler loginFailureHandler;
    
    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/",
                                "/register",
                                "/login",
                                "/test/**",
                                "/employee-login",
                                "/error",
                                                
                                "/trips/search",
                                "/trips/{tripId}",
                                "/trips/{tripId}/carriages/{carriageId}/**",      

                                "/css/**",
                                "/js/**",
                                "/images/**"
                        ).permitAll()
                        
                        .requestMatchers("/admin/**")
                        .hasRole("ADMIN")

                        .requestMatchers("/manager/**")
                        .hasRole("MANAGER")

                        .requestMatchers("/ticket-seller/**")
                        .hasRole("TICKET_SELLER")
        
                        .anyRequest()
                        .hasRole("CUSTOMER")
                )
                .formLogin(login -> login
                        .loginPage("/login")
                        .loginProcessingUrl("/login")
                        .usernameParameter("username")
                        .passwordParameter("password")
                        .successHandler(loginSuccessHandler)
                        .failureHandler(loginFailureHandler)
                )
                .logout(logout -> logout
                        .logoutUrl("/logout")
                        .logoutSuccessUrl("/trips/search")
                );

        return http.build();
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
