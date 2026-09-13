package com.propzen;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class PropzenApplicationTests {

    @Test
    void contextLoads() {
        // Verifies Spring context initializes properly with database and security beans
    }
}
