package com.propzen.property;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.property.entity.Property;
import com.propzen.property.repository.PropertyRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PropertyFilterIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private PropertyRepository propertyRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private UUID dealerId;

    @BeforeEach
    void setUp() {
        propertyRepository.deleteAll();
        dealerId = UUID.randomUUID();

        // Seed comprehensive test properties
        // 1. Noida Sector 150 3 BHK Apartment 1.20 Cr 1600 sqft (PUBLISHED)
        createAndSave("ATS Kingston Heath", "Noida", "Sector 150", "Sports City", "Apartment", "3 BHK",
                BigDecimal.valueOf(1.20), 1600, "Gym, Swimming Pool, Parking", "PUBLISHED", OffsetDateTime.now().minusDays(5));

        // 2. Noida Sector 150 2 BHK Apartment 0.85 Cr 1100 sqft (PUBLISHED)
        createAndSave("Godrej Palm Retreat", "Noida", "Sector 150", "Sector 150", "Apartment", "2 BHK",
                BigDecimal.valueOf(0.85), 1100, "Gym, Parking", "PUBLISHED", OffsetDateTime.now().minusDays(4));

        // 3. Noida Sector 137 3 BHK Apartment 1.10 Cr 1500 sqft (PUBLISHED)
        createAndSave("Paras Tierea", "Noida", "Sector 137", "Noida Expressway", "Apartment", "3 BHK",
                BigDecimal.valueOf(1.10), 1500, "Clubhouse, Parking", "PUBLISHED", OffsetDateTime.now().minusDays(3));

        // 4. Gurgaon Golf Course Road 4 BHK Villa 4.50 Cr 3500 sqft (PUBLISHED)
        createAndSave("DLF Camellias Villa", "Gurgaon", "Golf Course Road", "DLF Phase 5", "Villa", "4 BHK",
                BigDecimal.valueOf(4.50), 3500, "Private Pool, Gym, Parking", "PUBLISHED", OffsetDateTime.now().minusDays(2));

        // 5. Gurgaon Sector 82 13 BHK Hostels/Commercial (To verify 3 BHK does NOT match 13 BHK)
        createAndSave("Grand Co-Living 13 BHK", "Gurgaon", "Sector 82", "Vatika", "Commercial", "13 BHK",
                BigDecimal.valueOf(2.50), 4000, "Parking, Cafeteria", "PUBLISHED", OffsetDateTime.now().minusDays(1));

        // 6. Noida Sector 150 3 BHK Apartment - DRAFT (Must NOT be in public search)
        createAndSave("Draft Unapproved Tower", "Noida", "Sector 150", "Sports City", "Apartment", "3 BHK",
                BigDecimal.valueOf(1.15), 1550, "Gym", "DRAFT", OffsetDateTime.now());
    }

    private Property createAndSave(String title, String city, String sector, String locality,
                                   String propertyType, String bhk, BigDecimal priceCr, Integer sqft,
                                   String amenities, String status, OffsetDateTime createdAt) {
        Property p = new Property();
        p.setTitle(title);
        p.setCity(city);
        p.setSector(sector);
        p.setLocality(locality);
        p.setPropertyType(propertyType);
        p.setBhk(bhk);
        p.setPriceCr(priceCr);
        p.setSqft(sqft);
        p.setAmenities(amenities);
        p.setStatus(status);
        p.setVerificationStatus("PUBLISHED".equals(status) ? "VERIFIED" : "PENDING");
        p.setDealerId(dealerId);
        p.setCreatedAt(createdAt);
        p.setUpdatedAt(createdAt);
        return propertyRepository.save(p);
    }

    @Test
    @DisplayName("Filter Test 1: No filters - returns only published properties")
    void test1_NoFiltersReturnsPublishedOnly() throws Exception {
        mockMvc.perform(get("/api/v1/properties"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(5))
                .andExpect(jsonPath("$.data.content[*].title", not(hasItem("Draft Unapproved Tower"))));
    }

    @Test
    @DisplayName("Filter Test 2: City filter - returns only Noida properties")
    void test2_CityFilter() throws Exception {
        mockMvc.perform(get("/api/v1/properties?city=Noida"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(3))
                .andExpect(jsonPath("$.data.content[*].city", everyItem(equalToIgnoringCase("Noida"))));
    }

    @Test
    @DisplayName("Filter Test 3: Sector filter - returns only Sector 150")
    void test3_SectorFilter() throws Exception {
        mockMvc.perform(get("/api/v1/properties?sector=Sector 150"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(2))
                .andExpect(jsonPath("$.data.content[*].sector", everyItem(equalToIgnoringCase("Sector 150"))));
    }

    @Test
    @DisplayName("Filter Test 4: Locality filter - partial matching")
    void test4_LocalityFilter() throws Exception {
        mockMvc.perform(get("/api/v1/properties?locality=Sports City"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].title").value("ATS Kingston Heath"));
    }

    @Test
    @DisplayName("Filter Test 5: BHK filter - 3 BHK must NEVER match 13 BHK")
    void test5_BhkFilterAccurateMatching() throws Exception {
        mockMvc.perform(get("/api/v1/properties?bhk=3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(2))
                .andExpect(jsonPath("$.data.content[*].title", not(hasItem("Grand Co-Living 13 BHK"))))
                .andExpect(jsonPath("$.data.content[*].bhk", everyItem(containsString("3 BHK"))));
    }

    @Test
    @DisplayName("Filter Test 6: Property Type filter - Villa only")
    void test6_PropertyTypeFilter() throws Exception {
        mockMvc.perform(get("/api/v1/properties?propertyType=Villa"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].title").value("DLF Camellias Villa"));
    }

    @Test
    @DisplayName("Filter Test 7: Min Price filter (0.90 Cr)")
    void test7_MinPriceFilter() throws Exception {
        mockMvc.perform(get("/api/v1/properties?minPriceCr=0.90"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(4))
                .andExpect(jsonPath("$.data.content[*].title", not(hasItem("Godrej Palm Retreat"))));
    }

    @Test
    @DisplayName("Filter Test 8: Max Price filter in Lakhs (100 Lakhs = 1.00 Cr)")
    void test8_MaxPriceInLakhsFilter() throws Exception {
        // 100 Lakhs normalized to 1.00 Cr
        mockMvc.perform(get("/api/v1/properties?maxPrice=100"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].title").value("Godrej Palm Retreat"));
    }

    @Test
    @DisplayName("Filter Test 9: Min Sqft filter (1500 sqft)")
    void test9_MinSqftFilter() throws Exception {
        mockMvc.perform(get("/api/v1/properties?minSqft=1500"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(4))
                .andExpect(jsonPath("$.data.content[*].title", not(hasItem("Godrej Palm Retreat"))));
    }

    @Test
    @DisplayName("Filter Test 10: Max Sqft filter (1500 sqft)")
    void test10_MaxSqftFilter() throws Exception {
        mockMvc.perform(get("/api/v1/properties?maxSqft=1500"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(2));
    }

    @Test
    @DisplayName("Filter Test 11: City + BHK (Noida + 3 BHK)")
    void test11_CityPlusBhk() throws Exception {
        mockMvc.perform(get("/api/v1/properties?city=Noida&bhk=3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(2))
                .andExpect(jsonPath("$.data.content[*].city", everyItem(equalToIgnoringCase("Noida"))));
    }

    @Test
    @DisplayName("Filter Test 12: City + Budget (Noida + 80 Lakhs to 100 Lakhs)")
    void test12_CityPlusBudget() throws Exception {
        mockMvc.perform(get("/api/v1/properties?city=Noida&minPrice=80&maxPrice=100"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].title").value("Godrej Palm Retreat"));
    }

    @Test
    @DisplayName("Filter Test 13: City + Sector + BHK (Noida + Sector 150 + 3 BHK)")
    void test13_CityPlusSectorPlusBhk() throws Exception {
        mockMvc.perform(get("/api/v1/properties?city=Noida&sector=Sector 150&bhk=3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].title").value("ATS Kingston Heath"));
    }

    @Test
    @DisplayName("Filter Test 14: City + Sector + BHK + Budget")
    void test14_CityPlusSectorPlusBhkPlusBudget() throws Exception {
        mockMvc.perform(get("/api/v1/properties?city=Noida&sector=Sector 150&bhk=3&minPriceCr=1.0&maxPriceCr=1.5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].title").value("ATS Kingston Heath"));
    }

    @Test
    @DisplayName("Filter Test 15: Property Type + Budget (Apartment + 1.0 to 2.0 Cr)")
    void test15_PropertyTypePlusBudget() throws Exception {
        mockMvc.perform(get("/api/v1/properties?propertyType=Apartment&minPriceCr=1.0&maxPriceCr=2.0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(2));
    }

    @Test
    @DisplayName("Filter Test 16: Combined Filters (All exact criteria)")
    void test16_CombinedFilters() throws Exception {
        mockMvc.perform(get("/api/v1/properties?city=Noida&sector=Sector 150&bhk=3&propertyType=Apartment&minPriceCr=1.0&maxPriceCr=1.5&minSqft=1500&maxSqft=1700"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].title").value("ATS Kingston Heath"));
    }

    @Test
    @DisplayName("Filter Test 17: No matching results returns empty list with 200 OK")
    void test17_NoMatchingResults() throws Exception {
        mockMvc.perform(get("/api/v1/properties?city=Bangalore"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(0))
                .andExpect(jsonPath("$.data.content", hasSize(0)));
    }

    @Test
    @DisplayName("Filter Test 18: Invalid filter bounds returns 400 Bad Request")
    void test18_InvalidFilterBounds() throws Exception {
        // minPrice > maxPrice
        mockMvc.perform(get("/api/v1/properties?minPriceCr=5.0&maxPriceCr=1.0"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));

        // minSqft > maxSqft
        mockMvc.perform(get("/api/v1/properties?minSqft=2000&maxSqft=1000"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @DisplayName("Filter Test 19: Database-level pagination")
    void test19_Pagination() throws Exception {
        mockMvc.perform(get("/api/v1/properties?page=0&size=2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.size").value(2))
                .andExpect(jsonPath("$.data.totalElements").value(5))
                .andExpect(jsonPath("$.data.totalPages").value(3))
                .andExpect(jsonPath("$.data.content", hasSize(2)));
    }

    @Test
    @DisplayName("Filter Test 20: Safe Predefined Sorting")
    void test20_PredefinedSorting() throws Exception {
        // Price Low -> High
        mockMvc.perform(get("/api/v1/properties?sort=price_low"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].priceCr").value(0.85));

        // Price High -> Low
        mockMvc.perform(get("/api/v1/properties?sort=price_high"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].priceCr").value(4.5));
    }

    @Test
    @DisplayName("Filter Test 21: Search text (q) across fields")
    void test21_SearchTextKeyword() throws Exception {
        mockMvc.perform(get("/api/v1/properties?q=Camellias"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].title").value("DLF Camellias Villa"));
    }
}
