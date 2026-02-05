//
//  TrainingView.swift
//  VelociraptorMacOS
//
//  Training and Education Interface
//  Gap 0x10 - Interactive training modules for DFIR skills
//
//  Features:
//  - Interactive VQL tutorials
//  - Artifact development training
//  - Incident response scenarios
//  - Progress tracking
//  - Skill assessments
//
//  CDIF Pattern: FC-001 (Feature Complete)
//  Swift 6 Concurrency: @MainActor, Sendable
//

import SwiftUI
import Combine

// MARK: - Data Models

struct TrainingModule: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var description: String
    var category: TrainingCategory
    var difficulty: Difficulty
    var duration: Int // minutes
    var lessons: [Lesson]
    var completedLessons: Int
    var isUnlocked: Bool
    
    init(id: UUID = UUID(), title: String, description: String, category: TrainingCategory, difficulty: Difficulty, duration: Int, lessons: [Lesson] = [], completedLessons: Int = 0, isUnlocked: Bool = true) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.duration = duration
        self.lessons = lessons
        self.completedLessons = completedLessons
        self.isUnlocked = isUnlocked
    }
    
    var progress: Double {
        guard !lessons.isEmpty else { return 0 }
        return Double(completedLessons) / Double(lessons.count)
    }
}

struct Lesson: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var content: String
    var type: LessonType
    var isCompleted: Bool
    var exercises: [Exercise]
    
    init(id: UUID = UUID(), title: String, content: String, type: LessonType, isCompleted: Bool = false, exercises: [Exercise] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.isCompleted = isCompleted
        self.exercises = exercises
    }
}

struct Exercise: Identifiable, Hashable, Sendable {
    let id: UUID
    var question: String
    var type: ExerciseType
    var expectedOutput: String
    var hints: [String]
    
    init(id: UUID = UUID(), question: String, type: ExerciseType, expectedOutput: String = "", hints: [String] = []) {
        self.id = id
        self.question = question
        self.type = type
        self.expectedOutput = expectedOutput
        self.hints = hints
    }
}

enum TrainingCategory: String, CaseIterable, Sendable {
    case vqlBasics = "VQL Basics"
    case advancedVQL = "Advanced VQL"
    case artifacts = "Artifact Development"
    case incidentResponse = "Incident Response"
    case hunting = "Threat Hunting"
    case administration = "Server Administration"
    
    var icon: String {
        switch self {
        case .vqlBasics: return "book.fill"
        case .advancedVQL: return "function"
        case .artifacts: return "doc.text.fill"
        case .incidentResponse: return "exclamationmark.triangle.fill"
        case .hunting: return "magnifyingglass"
        case .administration: return "gearshape.2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .vqlBasics: return .blue
        case .advancedVQL: return .purple
        case .artifacts: return .orange
        case .incidentResponse: return .red
        case .hunting: return .green
        case .administration: return .gray
        }
    }
}

enum Difficulty: String, CaseIterable, Sendable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .yellow
        case .advanced: return .orange
        case .expert: return .red
        }
    }
}

enum LessonType: String, Sendable {
    case reading = "Reading"
    case interactive = "Interactive"
    case exercise = "Exercise"
    case quiz = "Quiz"
    case scenario = "Scenario"
}

enum ExerciseType: String, Sendable {
    case vqlQuery = "VQL Query"
    case multipleChoice = "Multiple Choice"
    case freeform = "Free Form"
}

// MARK: - ViewModel

@MainActor
final class TrainingViewModel: ObservableObject {
    @Published var modules: [TrainingModule] = []
    @Published var selectedModule: TrainingModule?
    @Published var selectedLesson: Lesson?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedCategory: TrainingCategory?
    @Published var showCertificates = false
    
    var filteredModules: [TrainingModule] {
        var result = modules
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var overallProgress: Double {
        guard !modules.isEmpty else { return 0 }
        let totalLessons = modules.reduce(0) { $0 + $1.lessons.count }
        let completedLessons = modules.reduce(0) { $0 + $1.completedLessons }
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }
    
    func loadModules() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load sample training modules
        if modules.isEmpty {
            modules = [
                TrainingModule(
                    title: "Introduction to VQL",
                    description: "Learn the fundamentals of Velociraptor Query Language",
                    category: .vqlBasics,
                    difficulty: .beginner,
                    duration: 30,
                    lessons: [
                        Lesson(title: "What is VQL?", content: "VQL (Velociraptor Query Language) is...", type: .reading, isCompleted: true),
                        Lesson(title: "Basic SELECT statements", content: "The SELECT statement...", type: .interactive, isCompleted: true),
                        Lesson(title: "Filtering with WHERE", content: "Filtering results...", type: .interactive),
                        Lesson(title: "Practice: Your First Query", content: "Now try writing...", type: .exercise)
                    ],
                    completedLessons: 2
                ),
                TrainingModule(
                    title: "Working with Plugins",
                    description: "Explore Velociraptor's powerful plugin system",
                    category: .vqlBasics,
                    difficulty: .beginner,
                    duration: 45,
                    lessons: [
                        Lesson(title: "Understanding Plugins", content: "Plugins are...", type: .reading),
                        Lesson(title: "Common Plugins", content: "The most used plugins...", type: .interactive),
                        Lesson(title: "Plugin Parameters", content: "Configuring plugins...", type: .interactive),
                        Lesson(title: "Practice: Process Listing", content: "Use pslist()...", type: .exercise),
                        Lesson(title: "Quiz: Plugin Knowledge", content: "Test your knowledge...", type: .quiz)
                    ],
                    completedLessons: 0
                ),
                TrainingModule(
                    title: "Advanced VQL Techniques",
                    description: "Master complex queries and data transformations",
                    category: .advancedVQL,
                    difficulty: .intermediate,
                    duration: 60,
                    lessons: [
                        Lesson(title: "Subqueries", content: "Nested queries...", type: .reading),
                        Lesson(title: "LET Statements", content: "Variables in VQL...", type: .interactive),
                        Lesson(title: "foreach()", content: "Iterating over results...", type: .interactive),
                        Lesson(title: "Aggregations", content: "Group and count...", type: .interactive),
                        Lesson(title: "Practice: Complex Analysis", content: "Combine techniques...", type: .exercise)
                    ],
                    completedLessons: 0,
                    isUnlocked: false
                ),
                TrainingModule(
                    title: "Creating Custom Artifacts",
                    description: "Build your own collection artifacts",
                    category: .artifacts,
                    difficulty: .intermediate,
                    duration: 90,
                    lessons: [
                        Lesson(title: "Artifact Structure", content: "Understanding YAML format...", type: .reading),
                        Lesson(title: "Parameters", content: "Defining parameters...", type: .interactive),
                        Lesson(title: "Sources", content: "VQL sources...", type: .interactive),
                        Lesson(title: "Testing Artifacts", content: "Validating your work...", type: .exercise),
                        Lesson(title: "Best Practices", content: "Tips and tricks...", type: .reading),
                        Lesson(title: "Project: Create an Artifact", content: "Build a complete artifact...", type: .scenario)
                    ],
                    completedLessons: 0
                ),
                TrainingModule(
                    title: "Incident Response Fundamentals",
                    description: "Learn systematic IR methodologies",
                    category: .incidentResponse,
                    difficulty: .intermediate,
                    duration: 120,
                    lessons: [
                        Lesson(title: "IR Lifecycle", content: "Preparation, Detection...", type: .reading),
                        Lesson(title: "Evidence Collection", content: "Volatile vs persistent...", type: .interactive),
                        Lesson(title: "Triage Techniques", content: "Quick assessment...", type: .interactive),
                        Lesson(title: "Timeline Analysis", content: "Building timelines...", type: .interactive),
                        Lesson(title: "Scenario: Ransomware Response", content: "Practice with a realistic...", type: .scenario),
                        Lesson(title: "Scenario: Data Exfiltration", content: "Investigate unauthorized...", type: .scenario)
                    ],
                    completedLessons: 0
                ),
                TrainingModule(
                    title: "Threat Hunting with Velociraptor",
                    description: "Proactive detection of adversary behavior",
                    category: .hunting,
                    difficulty: .advanced,
                    duration: 90,
                    lessons: [
                        Lesson(title: "Hunting Methodology", content: "Hypothesis-driven hunting...", type: .reading),
                        Lesson(title: "MITRE ATT&CK Mapping", content: "Using the framework...", type: .interactive),
                        Lesson(title: "Persistence Mechanisms", content: "Finding persistence...", type: .interactive),
                        Lesson(title: "Lateral Movement Detection", content: "Tracking movement...", type: .interactive),
                        Lesson(title: "Hunt: APT Simulation", content: "Find the adversary...", type: .scenario)
                    ],
                    completedLessons: 0,
                    isUnlocked: false
                )
            ]
        }
    }
    
    func completeLesson(_ lesson: Lesson, in module: TrainingModule) {
        if let moduleIndex = modules.firstIndex(where: { $0.id == module.id }),
           let lessonIndex = modules[moduleIndex].lessons.firstIndex(where: { $0.id == lesson.id }) {
            modules[moduleIndex].lessons[lessonIndex].isCompleted = true
            modules[moduleIndex].completedLessons = modules[moduleIndex].lessons.filter { $0.isCompleted }.count
            
            // Check if module is complete to unlock next
            if modules[moduleIndex].progress >= 1.0 {
                unlockNextModule(after: modules[moduleIndex])
            }
        }
    }
    
    private func unlockNextModule(after module: TrainingModule) {
        // Find and unlock next module in same category
        if let currentIndex = modules.firstIndex(where: { $0.id == module.id }) {
            for i in (currentIndex + 1)..<modules.count {
                if modules[i].category == module.category && !modules[i].isUnlocked {
                    modules[i].isUnlocked = true
                    break
                }
            }
        }
    }
}

// MARK: - Main View

struct TrainingView: View {
    @StateObject private var viewModel = TrainingViewModel()
    
    var body: some View {
        HSplitView {
            // Sidebar
            TrainingListView(viewModel: viewModel)
                .frame(minWidth: 300, idealWidth: 350, maxWidth: 450)
            
            // Content
            if let lesson = viewModel.selectedLesson, let module = viewModel.selectedModule {
                LessonView(lesson: lesson, module: module, viewModel: viewModel)
            } else if let module = viewModel.selectedModule {
                ModuleDetailView(module: module, viewModel: viewModel)
            } else {
                TrainingDashboard(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadModules()
        }
        .accessibilityIdentifier("training.main")
    }
}

// MARK: - Training List

struct TrainingListView: View {
    @ObservedObject var viewModel: TrainingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Training")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.showCertificates = true }) {
                    Image(systemName: "rosette")
                }
                .buttonStyle(.borderless)
            }
            .padding()
            
            // Progress Overview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Overall Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                ProgressView(value: viewModel.overallProgress)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search courses...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    TrainingCategoryPill(
                        title: "All",
                        isSelected: viewModel.selectedCategory == nil,
                        action: { viewModel.selectedCategory = nil }
                    )
                    
                    ForEach(TrainingCategory.allCases, id: \.self) { category in
                        TrainingCategoryPill(
                            title: category.rawValue,
                            isSelected: viewModel.selectedCategory == category,
                            action: { viewModel.selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Module List
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else {
                List(viewModel.filteredModules, selection: $viewModel.selectedModule) { module in
                    ModuleRow(module: module)
                        .tag(module)
                }
                .listStyle(.sidebar)
                .onChange(of: viewModel.selectedModule) { _, _ in
                    viewModel.selectedLesson = nil
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct TrainingCategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct ModuleRow: View {
    let module: TrainingModule
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(module.category.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: module.category.icon)
                    .foregroundColor(module.category.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(module.title)
                        .font(.headline)
                    if !module.isUnlocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                HStack(spacing: 8) {
                    Text(module.difficulty.rawValue)
                        .font(.caption)
                        .foregroundColor(module.difficulty.color)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(module.duration) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                ProgressView(value: module.progress)
                    .progressViewStyle(.linear)
                    .tint(module.category.color)
            }
        }
        .padding(.vertical, 4)
        .opacity(module.isUnlocked ? 1 : 0.6)
        .accessibilityIdentifier("training.module.\(module.id)")
    }
}

// MARK: - Training Dashboard

struct TrainingDashboard: View {
    @ObservedObject var viewModel: TrainingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome Header
                VStack(spacing: 8) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                    
                    Text("Welcome to Velociraptor Training")
                        .font(.title)
                    
                    Text("Master DFIR skills with interactive courses")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Quick Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    TrainingStatCard(
                        title: "Courses",
                        value: "\(viewModel.modules.count)",
                        icon: "book.fill",
                        color: .blue
                    )
                    TrainingStatCard(
                        title: "In Progress",
                        value: "\(viewModel.modules.filter { $0.progress > 0 && $0.progress < 1 }.count)",
                        icon: "clock.fill",
                        color: .orange
                    )
                    TrainingStatCard(
                        title: "Completed",
                        value: "\(viewModel.modules.filter { $0.progress >= 1 }.count)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    TrainingStatCard(
                        title: "Total Hours",
                        value: "\(viewModel.modules.reduce(0) { $0 + $1.duration } / 60)",
                        icon: "hourglass",
                        color: .purple
                    )
                }
                .padding(.horizontal, 40)
                
                // Category Overview
                Text("Learning Paths")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(TrainingCategory.allCases, id: \.self) { category in
                        LearningPathCard(
                            category: category,
                            moduleCount: viewModel.modules.filter { $0.category == category }.count,
                            action: { viewModel.selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
    }
}

struct TrainingStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct LearningPathCard: View {
    let category: TrainingCategory
    let moduleCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(category.color)
                
                Text(category.rawValue)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("\(moduleCount) courses")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Module Detail

struct ModuleDetailView: View {
    let module: TrainingModule
    @ObservedObject var viewModel: TrainingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: module.category.icon)
                                .foregroundColor(module.category.color)
                            Text(module.category.rawValue)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(module.title)
                            .font(.title)
                        
                        Text(module.description)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Label(module.difficulty.rawValue, systemImage: "chart.bar.fill")
                                .foregroundColor(module.difficulty.color)
                            Label("\(module.duration) min", systemImage: "clock")
                                .foregroundColor(.secondary)
                            Label("\(module.lessons.count) lessons", systemImage: "list.bullet")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                    
                    Spacer()
                    
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: module.progress)
                            .stroke(module.category.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(module.progress * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(width: 100, height: 100)
                }
                .padding(24)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Lessons List
                Text("Lessons")
                    .font(.headline)
                
                ForEach(Array(module.lessons.enumerated()), id: \.element.id) { index, lesson in
                    LessonRow(
                        lesson: lesson,
                        index: index + 1,
                        isLocked: !module.isUnlocked,
                        action: {
                            if module.isUnlocked {
                                viewModel.selectedLesson = lesson
                            }
                        }
                    )
                }
                
                Spacer()
            }
            .padding(24)
        }
        .accessibilityIdentifier("training.module.detail")
    }
}

struct LessonRow: View {
    let lesson: Lesson
    let index: Int
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(lesson.isCompleted ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                    
                    if lesson.isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                    } else if isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                    } else {
                        Text("\(index)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.headline)
                    HStack {
                        Text(lesson.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !lesson.exercises.isEmpty {
                            Text("• \(lesson.exercises.count) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? 0.6 : 1)
    }
}

// MARK: - Lesson View

struct LessonView: View {
    let lesson: Lesson
    let module: TrainingModule
    @ObservedObject var viewModel: TrainingViewModel
    @State private var showComplete = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { viewModel.selectedLesson = nil }) {
                    Label("Back to Module", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Text(lesson.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(lesson.title)
                        .font(.title)
                    
                    Text(lesson.content)
                        .foregroundColor(.secondary)
                    
                    if lesson.type == .interactive || lesson.type == .exercise {
                        // Interactive code editor placeholder
                        GroupBox("VQL Editor") {
                            TextEditor(text: .constant("SELECT * FROM info()"))
                                .font(.system(.body, design: .monospaced))
                                .frame(height: 150)
                                .padding(8)
                        }
                        
                        Button("Run Query") {
                            // Execute query
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if !lesson.exercises.isEmpty {
                        Text("Exercises")
                            .font(.headline)
                        
                        ForEach(lesson.exercises) { exercise in
                            GroupBox {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(exercise.question)
                                    
                                    if exercise.type == .vqlQuery {
                                        TextEditor(text: .constant(""))
                                            .font(.system(.body, design: .monospaced))
                                            .frame(height: 80)
                                            .padding(4)
                                            .background(Color(NSColor.textBackgroundColor))
                                            .cornerRadius(4)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            
            Divider()
            
            // Footer
            HStack {
                if lesson.isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if !lesson.isCompleted {
                    Button("Mark as Complete") {
                        viewModel.completeLesson(lesson, in: module)
                        showComplete = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Next Lesson") {
                    // Navigate to next lesson
                    if let currentIndex = module.lessons.firstIndex(where: { $0.id == lesson.id }),
                       currentIndex + 1 < module.lessons.count {
                        viewModel.selectedLesson = module.lessons[currentIndex + 1]
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .alert("Lesson Complete!", isPresented: $showComplete) {
            Button("Continue") { }
        } message: {
            Text("Great job! You've completed this lesson.")
        }
        .accessibilityIdentifier("training.lesson")
    }
}

// MARK: - Preview

#if DEBUG
struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingView()
            .frame(width: 1200, height: 800)
    }
}
#endif
