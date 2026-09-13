package com.propzen.crm.dto;

import java.util.HashMap;
import java.util.Map;

public class CrmAnalyticsDto {

    private long totalLeads;
    private long totalEnquiries;
    private long totalFollowUps;
    private long totalTasks;
    private long totalCommunications;

    private Map<String, Long> leadsByStage = new HashMap<>();
    private Map<String, Long> leadsByStatus = new HashMap<>();
    private Map<String, Long> leadsBySource = new HashMap<>();
    private Map<String, Long> tasksByStatus = new HashMap<>();
    private Map<String, Long> communicationsByStatus = new HashMap<>();
    private Map<String, Long> communicationsByChannel = new HashMap<>();

    private double followUpCompletionRate;
    private double taskCompletionRate;
    private double overallConversionRate;

    public CrmAnalyticsDto() {
    }

    public long getTotalLeads() {
        return totalLeads;
    }

    public void setTotalLeads(long totalLeads) {
        this.totalLeads = totalLeads;
    }

    public long getTotalEnquiries() {
        return totalEnquiries;
    }

    public void setTotalEnquiries(long totalEnquiries) {
        this.totalEnquiries = totalEnquiries;
    }

    public long getTotalFollowUps() {
        return totalFollowUps;
    }

    public void setTotalFollowUps(long totalFollowUps) {
        this.totalFollowUps = totalFollowUps;
    }

    public long getTotalTasks() {
        return totalTasks;
    }

    public void setTotalTasks(long totalTasks) {
        this.totalTasks = totalTasks;
    }

    public long getTotalCommunications() {
        return totalCommunications;
    }

    public void setTotalCommunications(long totalCommunications) {
        this.totalCommunications = totalCommunications;
    }

    public Map<String, Long> getLeadsByStage() {
        return leadsByStage;
    }

    public void setLeadsByStage(Map<String, Long> leadsByStage) {
        this.leadsByStage = leadsByStage;
    }

    public Map<String, Long> getLeadsByStatus() {
        return leadsByStatus;
    }

    public void setLeadsByStatus(Map<String, Long> leadsByStatus) {
        this.leadsByStatus = leadsByStatus;
    }

    public Map<String, Long> getLeadsBySource() {
        return leadsBySource;
    }

    public void setLeadsBySource(Map<String, Long> leadsBySource) {
        this.leadsBySource = leadsBySource;
    }

    public Map<String, Long> getTasksByStatus() {
        return tasksByStatus;
    }

    public void setTasksByStatus(Map<String, Long> tasksByStatus) {
        this.tasksByStatus = tasksByStatus;
    }

    public Map<String, Long> getCommunicationsByStatus() {
        return communicationsByStatus;
    }

    public void setCommunicationsByStatus(Map<String, Long> communicationsByStatus) {
        this.communicationsByStatus = communicationsByStatus;
    }

    public Map<String, Long> getCommunicationsByChannel() {
        return communicationsByChannel;
    }

    public void setCommunicationsByChannel(Map<String, Long> communicationsByChannel) {
        this.communicationsByChannel = communicationsByChannel;
    }

    public double getFollowUpCompletionRate() {
        return followUpCompletionRate;
    }

    public void setFollowUpCompletionRate(double followUpCompletionRate) {
        this.followUpCompletionRate = followUpCompletionRate;
    }

    public double getTaskCompletionRate() {
        return taskCompletionRate;
    }

    public void setTaskCompletionRate(double taskCompletionRate) {
        this.taskCompletionRate = taskCompletionRate;
    }

    public double getOverallConversionRate() {
        return overallConversionRate;
    }

    public void setOverallConversionRate(double overallConversionRate) {
        this.overallConversionRate = overallConversionRate;
    }
}
