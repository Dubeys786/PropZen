package com.propzen.ai.dto;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MarketIntelligenceDto implements Serializable {

    private String city;
    private String sector;
    private boolean sufficientData;
    private String statusMessage; // e.g. "SUFFICIENT_DATA" or "INSUFFICIENT_DATA"
    private long totalActiveListings;
    private BigDecimal averageAskingPriceCr;
    private Map<String, Long> demandByBhk = new HashMap<>();
    private List<String> marketTrends = new ArrayList<>();
    private String priceTrendIndicator; // INCREASING, STABLE, DECREASING

    public MarketIntelligenceDto() {
    }

    public static MarketIntelligenceDto insufficientData(String city, String sector) {
        MarketIntelligenceDto dto = new MarketIntelligenceDto();
        dto.city = city;
        dto.sector = sector;
        dto.sufficientData = false;
        dto.statusMessage = "INSUFFICIENT_DATA";
        dto.priceTrendIndicator = "UNKNOWN";
        dto.marketTrends.add("Insufficient listing volume in this area to generate authoritative price trend models.");
        return dto;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getSector() {
        return sector;
    }

    public void setSector(String sector) {
        this.sector = sector;
    }

    public boolean isSufficientData() {
        return sufficientData;
    }

    public void setSufficientData(boolean sufficientData) {
        this.sufficientData = sufficientData;
    }

    public String getStatusMessage() {
        return statusMessage;
    }

    public void setStatusMessage(String statusMessage) {
        this.statusMessage = statusMessage;
    }

    public long getTotalActiveListings() {
        return totalActiveListings;
    }

    public void setTotalActiveListings(long totalActiveListings) {
        this.totalActiveListings = totalActiveListings;
    }

    public BigDecimal getAverageAskingPriceCr() {
        return averageAskingPriceCr;
    }

    public void setAverageAskingPriceCr(BigDecimal averageAskingPriceCr) {
        this.averageAskingPriceCr = averageAskingPriceCr;
    }

    public Map<String, Long> getDemandByBhk() {
        return demandByBhk;
    }

    public void setDemandByBhk(Map<String, Long> demandByBhk) {
        this.demandByBhk = demandByBhk;
    }

    public List<String> getMarketTrends() {
        return marketTrends;
    }

    public void setMarketTrends(List<String> marketTrends) {
        this.marketTrends = marketTrends;
    }

    public String getPriceTrendIndicator() {
        return priceTrendIndicator;
    }

    public void setPriceTrendIndicator(String priceTrendIndicator) {
        this.priceTrendIndicator = priceTrendIndicator;
    }
}
