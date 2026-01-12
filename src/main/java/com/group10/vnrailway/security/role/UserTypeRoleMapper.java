package com.group10.vnrailway.security.role;

import org.springframework.security.access.AccessDeniedException;

import com.group10.vnrailway.entity.Employee;
import com.group10.vnrailway.entity.User;

import java.util.Arrays;

import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public enum UserTypeRoleMapper {

    CUSTOMER("KH") {
        @Override
        public Role resolve(User user, Employee employee) {
            return Role.ROLE_CUSTOMER;
        }
    },

    EMPLOYEE("NV") {
        @Override
        public Role resolve(User user, Employee employee) {
            if (employee == null) {
                throw new AccessDeniedException("Nhân viên không hợp lệ.");
            }
            return EmployeePositionRoleMapper.fromDbCode(employee.getPosition());
        }
    };

    private final String dbCode;

    public abstract Role resolve(User user, Employee employee);

    public static Role resolveRole(User user, Employee employee) {
        String userType = user.getUserType();

        return Arrays.stream(values())
                .filter(t -> t.dbCode.equals(userType))
                .findFirst()
                .orElseThrow(() ->
                        new AccessDeniedException("Loại người dùng không hợp lệ.")
                )
                .resolve(user, employee);
    }
}
