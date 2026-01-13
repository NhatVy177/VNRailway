package com.group10.vnrailway.security.user;

import java.util.Collection;
import java.util.List;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import com.group10.vnrailway.entity.Account;
import com.group10.vnrailway.entity.Employee;
import com.group10.vnrailway.entity.User;
import com.group10.vnrailway.security.role.Role;
import com.group10.vnrailway.security.role.UserTypeRoleMapper;

import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public class CustomUserDetails implements UserDetails {

    private final Account account;
    private final User user;
    private final Employee employee;

    public String getFullName() {
        boolean isAdmin = getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals(Role.ROLE_ADMIN.name()));

        if (isAdmin) {
            return "QUẢN TRỊ VIÊN";
        }

        return user.getFullName();
    }

    public boolean isEmployee() {
        return employee != null;
    }

    @Override
    public String getUsername() {
        if (employee != null) {
            return employee.getId();
        }
        return user.getPhoneNumber();
    }

    @Override
    public String getPassword() {
        return account.getPassword();
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        Role role = UserTypeRoleMapper.resolveRole(user, employee);
        return List.of(new SimpleGrantedAuthority(role.name()));
    }

    @Override public boolean isAccountNonExpired() { return true; }
    @Override public boolean isAccountNonLocked() { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled() { return true; }
}
