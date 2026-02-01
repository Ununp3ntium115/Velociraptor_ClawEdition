//
//  ReportsView.swift
//  VelociraptorMacOS
//
//  Report generation and management interface
//  Implements Gap 0x0B: Reports
//

import SwiftUI

// MARK: - Reports View

/// Main reports interface
struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    
    var body: some View {
        HSplitView {
            // Left: Report templates and history
            ReportsSidebar(viewModel: viewModel)
                .frame(minWidth: 280, maxWidth: 350)
            
            // Right: Report preview/builder
            ReportContentPane(viewModel: viewModel)
                .frame(minWidth: 500)
        }
        .navigationTitle("Reports")
        .toolbar {
            ReportsToolbar(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showGenerateSheet) {
            GenerateReportSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showScheduleSheet) {
            ScheduleReportSheet(viewModel: viewModel)
        }
        .accessibilityIdentifier("reports_view")
    }
}

// MARK: - Reports Sidebar

struct ReportsSidebar: View {
    @ObservedObject var viewModel: ReportsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search reports...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding()
            
            Divider()
            
            List(selection: $viewModel.selectedReportId) {
                // Templates
                Section("Templates") {
                    ForEach(viewModel.templates) { template in
                        ReportTemplateRow(template: template)
                            .tag("template-\(template.id)")
                    }
                }
                
                // Recent Reports
                Section("Recent Reports") {
                    ForEach(viewModel.filteredReports) { report in
                        ReportRow(report: report, viewModel: viewModel)
                            .tag(report.id)
                    }
                }
                
                // Scheduled
                Section("Scheduled") {
                    ForEach(viewModel.scheduledReports) { schedule in
                        ScheduledReportRow(schedule: schedule)
                            .tag("schedule-\(schedule.id)")
                    }
                }
            }
            .listStyle(.sidebar)
            .accessibilityIdentifier("reports_list")
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ReportTemplateRow: View {
    let template: ReportTemplate
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: template.icon)
                .foregroundColor(template.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityIdentifier("report_template_\(template.id)")
    }
}

struct ReportRow: View {
    let report: GeneratedReport
    @ObservedObject var viewModel: ReportsViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: report.format.icon)
                .foregroundColor(report.format.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(report.name)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(report.createdFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if report.status == .generating {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
            }
            
            Spacer()
            
            ReportStatusBadge(status: report.status)
        }
        .contextMenu {
            Button("Open") { viewModel.openReport(report) }
            Button("Download") { viewModel.downloadReport(report) }
            Divider()
            Button("Delete", role: .destructive) { viewModel.deleteReport(report) }
        }
        .accessibilityIdentifier("report_row_\(report.id)")
    }
}

struct ScheduledReportRow: View {
    let schedule: ReportSchedule
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge")
                .foregroundColor(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.name)
                Text(schedule.frequencyDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(schedule.isEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
        .accessibilityIdentifier("scheduled_report_\(schedule.id)")
    }
}

struct ReportStatusBadge: View {
    let status: ReportStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(4)
    }
}

// MARK: - Report Content Pane

struct ReportContentPane: View {
    @ObservedObject var viewModel: ReportsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let report = viewModel.selectedReport {
                ReportPreview(report: report, viewModel: viewModel)
            } else if let template = viewModel.selectedTemplate {
                TemplateDetails(template: template, viewModel: viewModel)
            } else {
                ReportsEmptyState(viewModel: viewModel)
            }
        }
        .accessibilityIdentifier("report_content_pane")
    }
}

// MARK: - Report Preview

struct ReportPreview: View {
    let report: GeneratedReport
    @ObservedObject var viewModel: ReportsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.name)
                        .font(.headline)
                    
                    HStack {
                        Label(report.format.displayName, systemImage: report.format.icon)
                        Text("•")
                        Text(report.sizeFormatted)
                        Text("•")
                        Text(report.createdFormatted)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { viewModel.openReport(report) }) {
                        Label("Open", systemImage: "arrow.up.forward.square")
                    }
                    
                    Button(action: { viewModel.downloadReport(report) }) {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            
            Divider()
            
            // Preview
            ScrollView {
                if report.format == .html || report.format == .markdown {
                    // Rich preview
                    ReportHTMLPreview(content: report.previewContent)
                        .padding()
                } else {
                    // PDF preview placeholder
                    VStack(spacing: 16) {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        
                        Text("PDF Preview")
                            .font(.headline)
                        
                        Text("Click 'Open' to view the full document")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            
            Divider()
            
            // Metadata
            ReportMetadataBar(report: report)
        }
    }
}

struct ReportHTMLPreview: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(content)
                .font(.system(.body, design: .default))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ReportMetadataBar: View {
    let report: GeneratedReport
    
    var body: some View {
        HStack {
            if let hunt = report.huntId {
                Label(hunt, systemImage: "binoculars")
                    .font(.caption)
            }
            
            if let client = report.clientId {
                Label(client, systemImage: "desktopcomputer")
                    .font(.caption)
            }
            
            Spacer()
            
            Text("Generated by \(report.generatedBy)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Template Details

struct TemplateDetails: View {
    let template: ReportTemplate
    @ObservedObject var viewModel: ReportsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: template.icon)
                    .font(.largeTitle)
                    .foregroundColor(template.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                    Text(template.description)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { 
                    viewModel.selectedTemplateForGeneration = template
                    viewModel.showGenerateSheet = true
                }) {
                    Label("Generate Report", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Template info
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Sections
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Included Sections")
                            .font(.headline)
                        
                        ForEach(template.sections, id: \.self) { section in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(section)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Data sources
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Sources")
                            .font(.headline)
                        
                        ForEach(template.dataSources, id: \.self) { source in
                            HStack {
                                Image(systemName: "cylinder")
                                    .foregroundColor(.blue)
                                Text(source)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Output formats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Formats")
                            .font(.headline)
                        
                        HStack {
                            ForEach(template.supportedFormats, id: \.self) { format in
                                Label(format.displayName, systemImage: format.icon)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(format.color.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Empty State

struct ReportsEmptyState: View {
    @ObservedObject var viewModel: ReportsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Report Selected")
                .font(.headline)
            
            Text("Select a template to generate a new report, or choose an existing report to preview")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            Button(action: { viewModel.showGenerateSheet = true }) {
                Label("Generate Report", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("reports_empty_state")
    }
}

// MARK: - Toolbar

struct ReportsToolbar: ToolbarContent {
    @ObservedObject var viewModel: ReportsViewModel
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { viewModel.showGenerateSheet = true }) {
                Label("Generate", systemImage: "doc.badge.plus")
            }
            .accessibilityIdentifier("generate_report_button")
            
            Button(action: { viewModel.showScheduleSheet = true }) {
                Label("Schedule", systemImage: "clock.badge.plus")
            }
            .accessibilityIdentifier("schedule_report_button")
        }
    }
}

// MARK: - Generate Report Sheet

struct GenerateReportSheet: View {
    @ObservedObject var viewModel: ReportsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTemplate: ReportTemplate?
    @State private var reportName = ""
    @State private var format: ReportFormat = .pdf
    @State private var huntId = ""
    @State private var clientId = ""
    @State private var includeSections: Set<String> = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Generate Report")
                .font(.headline)
            
            Form {
                // Template selection
                Picker("Template", selection: $selectedTemplate) {
                    Text("Select template...").tag(nil as ReportTemplate?)
                    ForEach(viewModel.templates) { template in
                        Text(template.name).tag(template as ReportTemplate?)
                    }
                }
                
                TextField("Report Name", text: $reportName)
                
                Picker("Format", selection: $format) {
                    ForEach(ReportFormat.allCases) { format in
                        Label(format.displayName, systemImage: format.icon)
                            .tag(format)
                    }
                }
                
                Section("Scope") {
                    TextField("Hunt ID (optional)", text: $huntId)
                    TextField("Client ID (optional)", text: $clientId)
                }
                
                if let template = selectedTemplate {
                    Section("Sections") {
                        ForEach(template.sections, id: \.self) { section in
                            Toggle(section, isOn: Binding(
                                get: { includeSections.contains(section) },
                                set: { if $0 { includeSections.insert(section) } else { includeSections.remove(section) } }
                            ))
                        }
                    }
                }
            }
            .frame(height: 350)
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Generate") {
                    Task {
                        await viewModel.generateReport(
                            template: selectedTemplate ?? viewModel.templates[0],
                            name: reportName,
                            format: format,
                            huntId: huntId.isEmpty ? nil : huntId,
                            clientId: clientId.isEmpty ? nil : clientId
                        )
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(reportName.isEmpty || selectedTemplate == nil)
            }
        }
        .padding()
        .frame(width: 500)
        .onAppear {
            if let template = viewModel.selectedTemplateForGeneration {
                selectedTemplate = template
                includeSections = Set(template.sections)
            }
        }
        .accessibilityIdentifier("generate_report_sheet")
    }
}

// MARK: - Schedule Report Sheet

struct ScheduleReportSheet: View {
    @ObservedObject var viewModel: ReportsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedTemplate: ReportTemplate?
    @State private var frequency: ScheduleFrequency = .daily
    @State private var time = Date()
    @State private var format: ReportFormat = .pdf
    @State private var recipients: [String] = []
    @State private var recipientInput = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Schedule Report")
                .font(.headline)
            
            Form {
                TextField("Schedule Name", text: $name)
                
                Picker("Template", selection: $selectedTemplate) {
                    Text("Select template...").tag(nil as ReportTemplate?)
                    ForEach(viewModel.templates) { template in
                        Text(template.name).tag(template as ReportTemplate?)
                    }
                }
                
                Picker("Frequency", selection: $frequency) {
                    ForEach(ScheduleFrequency.allCases) { freq in
                        Text(freq.displayName).tag(freq)
                    }
                }
                
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                
                Picker("Format", selection: $format) {
                    ForEach(ReportFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                
                Section("Recipients") {
                    HStack {
                        TextField("Email address", text: $recipientInput)
                        Button("Add") {
                            if !recipientInput.isEmpty {
                                recipients.append(recipientInput)
                                recipientInput = ""
                            }
                        }
                    }
                    
                    ForEach(recipients, id: \.self) { recipient in
                        HStack {
                            Text(recipient)
                            Spacer()
                            Button(action: { recipients.removeAll { $0 == recipient } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(height: 400)
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Schedule") {
                    viewModel.scheduleReport(
                        name: name,
                        template: selectedTemplate ?? viewModel.templates[0],
                        frequency: frequency,
                        time: time,
                        format: format,
                        recipients: recipients
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || selectedTemplate == nil)
            }
        }
        .padding()
        .frame(width: 500)
        .accessibilityIdentifier("schedule_report_sheet")
    }
}

// MARK: - Models

enum ReportFormat: String, CaseIterable, Identifiable, Hashable {
    case pdf, html, markdown, csv, json
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .html: return "HTML"
        case .markdown: return "Markdown"
        case .csv: return "CSV"
        case .json: return "JSON"
        }
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .html: return "globe"
        case .markdown: return "text.alignleft"
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        }
    }
    
    var color: Color {
        switch self {
        case .pdf: return .red
        case .html: return .orange
        case .markdown: return .blue
        case .csv: return .green
        case .json: return .purple
        }
    }
}

enum ReportStatus: String {
    case ready, generating, failed
    
    var displayName: String {
        switch self {
        case .ready: return "Ready"
        case .generating: return "Generating"
        case .failed: return "Failed"
        }
    }
    
    var color: Color {
        switch self {
        case .ready: return .green
        case .generating: return .blue
        case .failed: return .red
        }
    }
}

enum ScheduleFrequency: String, CaseIterable, Identifiable {
    case daily, weekly, monthly
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

struct ReportTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let sections: [String]
    let dataSources: [String]
    let supportedFormats: [ReportFormat]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ReportTemplate, rhs: ReportTemplate) -> Bool {
        lhs.id == rhs.id
    }
}

struct GeneratedReport: Identifiable {
    let id: String
    let name: String
    let format: ReportFormat
    let status: ReportStatus
    let created: Date
    let size: Int64
    let huntId: String?
    let clientId: String?
    let generatedBy: String
    let previewContent: String
    
    var createdFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: created, relativeTo: Date())
    }
    
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct ReportSchedule: Identifiable {
    let id: String
    let name: String
    let templateId: String
    let frequency: ScheduleFrequency
    let time: Date
    let format: ReportFormat
    let recipients: [String]
    var isEnabled: Bool
    let lastRun: Date?
    let nextRun: Date
    
    var frequencyDescription: String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return "\(frequency.displayName) at \(timeFormatter.string(from: time))"
    }
}

// MARK: - View Model

@MainActor
class ReportsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var reports: [GeneratedReport] = GeneratedReport.sampleReports
    @Published var scheduledReports: [ReportSchedule] = ReportSchedule.sampleSchedules
    @Published var selectedReportId: String?
    
    @Published var searchText = ""
    @Published var showGenerateSheet = false
    @Published var showScheduleSheet = false
    
    @Published var selectedTemplateForGeneration: ReportTemplate?
    
    // MARK: - Templates
    
    let templates: [ReportTemplate] = [
        ReportTemplate(
            id: "executive-summary",
            name: "Executive Summary",
            description: "High-level overview for stakeholders",
            icon: "chart.pie",
            color: .blue,
            sections: ["Overview", "Key Findings", "Timeline", "Recommendations", "Appendix"],
            dataSources: ["Hunt Results", "Client Metadata", "VQL Queries"],
            supportedFormats: [.pdf, .html]
        ),
        ReportTemplate(
            id: "incident-response",
            name: "Incident Response Report",
            description: "Detailed IR documentation",
            icon: "exclamationmark.triangle",
            color: .red,
            sections: ["Incident Summary", "Scope", "Timeline", "Indicators", "Containment", "Eradication", "Recovery", "Lessons Learned"],
            dataSources: ["Hunt Results", "Artifacts", "Timeline Data", "Evidence"],
            supportedFormats: [.pdf, .html, .markdown]
        ),
        ReportTemplate(
            id: "hunt-results",
            name: "Hunt Results",
            description: "Detailed hunt findings",
            icon: "binoculars",
            color: .green,
            sections: ["Hunt Parameters", "Results Summary", "Detailed Findings", "Statistics", "Raw Data"],
            dataSources: ["Hunt Results", "VQL Output"],
            supportedFormats: [.pdf, .html, .csv, .json]
        ),
        ReportTemplate(
            id: "compliance",
            name: "Compliance Report",
            description: "Regulatory compliance documentation",
            icon: "checkmark.shield",
            color: .purple,
            sections: ["Compliance Summary", "Control Status", "Findings", "Evidence", "Remediation Plan"],
            dataSources: ["Compliance Checks", "Policy Data", "Audit Logs"],
            supportedFormats: [.pdf]
        ),
        ReportTemplate(
            id: "threat-intel",
            name: "Threat Intelligence Report",
            description: "IOC and threat analysis",
            icon: "shield.lefthalf.filled",
            color: .orange,
            sections: ["Threat Overview", "IOCs", "TTPs", "Mitigations", "References"],
            dataSources: ["YARA Matches", "Sigma Rules", "IOC Database"],
            supportedFormats: [.pdf, .html, .json]
        ),
    ]
    
    // MARK: - Computed Properties
    
    var selectedReport: GeneratedReport? {
        guard let id = selectedReportId, !id.hasPrefix("template-"), !id.hasPrefix("schedule-") else { return nil }
        return reports.first { $0.id == id }
    }
    
    var selectedTemplate: ReportTemplate? {
        guard let id = selectedReportId, id.hasPrefix("template-") else { return nil }
        let templateId = String(id.dropFirst(9))
        return templates.first { $0.id == templateId }
    }
    
    var filteredReports: [GeneratedReport] {
        guard !searchText.isEmpty else { return reports }
        return reports.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // MARK: - Methods
    
    func generateReport(template: ReportTemplate, name: String, format: ReportFormat, huntId: String?, clientId: String?) async {
        let report = GeneratedReport(
            id: UUID().uuidString,
            name: name,
            format: format,
            status: .generating,
            created: Date(),
            size: 0,
            huntId: huntId,
            clientId: clientId,
            generatedBy: "Current User",
            previewContent: ""
        )
        
        reports.insert(report, at: 0)
        selectedReportId = report.id
        
        // Simulate generation
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = GeneratedReport(
                id: report.id,
                name: name,
                format: format,
                status: .ready,
                created: Date(),
                size: Int64.random(in: 50000...500000),
                huntId: huntId,
                clientId: clientId,
                generatedBy: "Current User",
                previewContent: "# \(name)\n\nGenerated on \(Date())\n\n## Summary\n\nThis report contains analysis results..."
            )
        }
    }
    
    func scheduleReport(name: String, template: ReportTemplate, frequency: ScheduleFrequency, time: Date, format: ReportFormat, recipients: [String]) {
        let schedule = ReportSchedule(
            id: UUID().uuidString,
            name: name,
            templateId: template.id,
            frequency: frequency,
            time: time,
            format: format,
            recipients: recipients,
            isEnabled: true,
            lastRun: nil,
            nextRun: Date().addingTimeInterval(86400)
        )
        scheduledReports.append(schedule)
    }
    
    func openReport(_ report: GeneratedReport) {
        // TODO: Open in preview
        print("Open report: \(report.name)")
    }
    
    func downloadReport(_ report: GeneratedReport) {
        // TODO: Download to disk
        print("Download report: \(report.name)")
    }
    
    func deleteReport(_ report: GeneratedReport) {
        reports.removeAll { $0.id == report.id }
        if selectedReportId == report.id {
            selectedReportId = nil
        }
    }
}

// MARK: - Sample Data

extension GeneratedReport {
    static let sampleReports: [GeneratedReport] = [
        GeneratedReport(
            id: "rpt-1",
            name: "Ransomware Investigation - ACME Corp",
            format: .pdf,
            status: .ready,
            created: Date().addingTimeInterval(-3600),
            size: 245760,
            huntId: "H.ABC123",
            clientId: nil,
            generatedBy: "Alice",
            previewContent: "# Ransomware Investigation\n\n## Executive Summary\n\nThis report documents the ransomware incident affecting ACME Corporation..."
        ),
        GeneratedReport(
            id: "rpt-2",
            name: "Weekly Hunt Summary",
            format: .html,
            status: .ready,
            created: Date().addingTimeInterval(-86400),
            size: 128000,
            huntId: nil,
            clientId: nil,
            generatedBy: "System",
            previewContent: "# Weekly Hunt Summary\n\n## Overview\n\n15 hunts completed this week..."
        ),
        GeneratedReport(
            id: "rpt-3",
            name: "Compliance Audit Q4",
            format: .pdf,
            status: .ready,
            created: Date().addingTimeInterval(-172800),
            size: 512000,
            huntId: nil,
            clientId: nil,
            generatedBy: "Bob",
            previewContent: "# Compliance Audit Report\n\nQ4 2025 Assessment..."
        ),
    ]
}

extension ReportSchedule {
    static let sampleSchedules: [ReportSchedule] = [
        ReportSchedule(
            id: "sched-1",
            name: "Daily Security Summary",
            templateId: "executive-summary",
            frequency: .daily,
            time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
            format: .pdf,
            recipients: ["security@company.com"],
            isEnabled: true,
            lastRun: Date().addingTimeInterval(-86400),
            nextRun: Date().addingTimeInterval(43200)
        ),
        ReportSchedule(
            id: "sched-2",
            name: "Weekly Compliance Report",
            templateId: "compliance",
            frequency: .weekly,
            time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            format: .pdf,
            recipients: ["compliance@company.com", "ciso@company.com"],
            isEnabled: true,
            lastRun: Date().addingTimeInterval(-604800),
            nextRun: Date().addingTimeInterval(259200)
        ),
    ]
}

// MARK: - Preview

#Preview {
    ReportsView()
        .frame(width: 1000, height: 700)
}
