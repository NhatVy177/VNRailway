package com.group10.vnrailway.security.user;

import java.util.Optional;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.group10.vnrailway.entity.Account;
import com.group10.vnrailway.entity.Employee;
import com.group10.vnrailway.entity.User;
import com.group10.vnrailway.repository.AccountRepository;
import com.group10.vnrailway.repository.EmployeeRepository;
import com.group10.vnrailway.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final AccountRepository accountRepository;
    private final UserRepository userRepository;
    private final EmployeeRepository employeeRepository;

    @Override
    public UserDetails loadUserByUsername(String identifier) throws UsernameNotFoundException {

        Optional<Employee> empOpt = employeeRepository.findByUserId(identifier);

        Account account = empOpt.isPresent()
            ? accountRepository.findByUserId(identifier)
                .orElseThrow(() ->
                    new UsernameNotFoundException(
                        "Không tìm thấy tài khoản với mã nhân viên: " + identifier
                    )
                )
            : accountRepository.findByPhone(identifier)
                .orElseThrow(() ->
                    new UsernameNotFoundException(
                        "Không tìm thấy tài khoản với SDT: " + identifier
                    )
                );

        User user = userRepository.findById(account.getUserId())
            .orElseThrow(() ->
                new UsernameNotFoundException(
                    "Không tìm thấy người dùng: " + account.getUserId()
                )
            );

        Employee employee = empOpt.orElse(null);

        return new CustomUserDetails(account, user, employee);
    }
}
