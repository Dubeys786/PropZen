package com.propzen.common.database.probe;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
class UserConnectionProbeRepositoryTest {

    @Autowired
    private UserConnectionProbeRepository probeRepository;

    @Test
    void testDatabaseConnectivityPingReturnsOne() {
        Integer ping = probeRepository.executeConnectivityPing();
        assertNotNull(ping, "Database ping result must not be null");
        assertEquals(1, ping, "Database SELECT 1 ping must return 1");
    }

    @Test
    void testFindAllExecutesSafelyWithoutException() {
        assertDoesNotThrow(() -> {
            long count = probeRepository.count();
            assertTrue(count >= 0, "Record count must be non-negative");
        });
    }
}
