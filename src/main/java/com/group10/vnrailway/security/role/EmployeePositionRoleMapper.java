package com.group10.vnrailway.security.role;

import java.util.Arrays;

import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public enum EmployeePositionRoleMapper {

    ADMIN("AD", Role.ROLE_ADMIN),
    MANAGER("QL", Role.ROLE_MANAGER),
    TICKET_SELLER("BV", Role.ROLE_TICKET_SELLER);

    private final String dbCode;
    private final Role role;

    public Role getRole() {
        return role;
    }

    public static Role fromDbCode(String code) {
        return Arrays.stream(values())
            .filter(p -> p.dbCode.equals(code))
            .findFirst()
            .map(EmployeePositionRoleMapper::getRole)
            .orElse(null);
    }
}
