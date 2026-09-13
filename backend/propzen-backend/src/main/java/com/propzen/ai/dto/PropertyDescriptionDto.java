package com.propzen.ai.dto;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class PropertyDescriptionDto implements Serializable {

    private String shortDescription;
    private String detailedDescription;
    private List<String> highlights = new ArrayList<>();
    private String seoTitle;
    private String seoDescription;
    private List<String> keywords = new ArrayList<>();

    public PropertyDescriptionDto() {
    }

    public PropertyDescriptionDto(String shortDescription, String detailedDescription,
                                  List<String> highlights, String seoTitle,
                                  String seoDescription, List<String> keywords) {
        this.shortDescription = shortDescription;
        this.detailedDescription = detailedDescription;
        this.highlights = highlights != null ? highlights : new ArrayList<>();
        this.seoTitle = seoTitle;
        this.seoDescription = seoDescription;
        this.keywords = keywords != null ? keywords : new ArrayList<>();
    }

    public String getShortDescription() {
        return shortDescription;
    }

    public void setShortDescription(String shortDescription) {
        this.shortDescription = shortDescription;
    }

    public String getDetailedDescription() {
        return detailedDescription;
    }

    public void setDetailedDescription(String detailedDescription) {
        this.detailedDescription = detailedDescription;
    }

    public List<String> getHighlights() {
        return highlights;
    }

    public void setHighlights(List<String> highlights) {
        this.highlights = highlights;
    }

    public String getSeoTitle() {
        return seoTitle;
    }

    public void setSeoTitle(String seoTitle) {
        this.seoTitle = seoTitle;
    }

    public String getSeoDescription() {
        return seoDescription;
    }

    public void setSeoDescription(String seoDescription) {
        this.seoDescription = seoDescription;
    }

    public List<String> getKeywords() {
        return keywords;
    }

    public void setKeywords(List<String> keywords) {
        this.keywords = keywords;
    }
}
