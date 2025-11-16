import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var locationManager: LocationManager

    @Binding var jumpToLocationId: String?

    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.1351, longitude: 11.5820),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    @State private var selectedLocation: LocationData?
    @State private var showFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var selectedStatuses: Set<LocationStatus> = []
    @State private var isAutoTriggered = false

    init(jumpToLocationId: Binding<String?> = .constant(nil)) {
        self._jumpToLocationId = jumpToLocationId
    }

    private var filteredLocations: [LocationData] {
        gameManager.locations.filter { location in
            // Category filter - match if no categories selected OR location category is in selected categories
            let categoryMatch = selectedCategories.isEmpty || selectedCategories.contains(location.category)

            // Status filter - match if no statuses selected OR location status is in selected statuses
            let statusMatch: Bool
            if selectedStatuses.isEmpty {
                statusMatch = true
            } else {
                let isVisited = gameManager.userProgress?.locationsVisited.contains(location.id) ?? false
                let quizzesForLocation = gameManager.getQuizzesForLocation(location.id)
                let completedQuizzes = quizzesForLocation.filter { gameManager.userProgress?.quizzesCompleted.contains($0.id) ?? false }

                let locationStatus: LocationStatus
                if !isVisited {
                    locationStatus = .locked
                } else if !quizzesForLocation.isEmpty && completedQuizzes.count == quizzesForLocation.count {
                    locationStatus = .completed
                } else {
                    locationStatus = .unlocked
                }

                statusMatch = selectedStatuses.contains(locationStatus)
            }

            return categoryMatch && statusMatch
        }
    }

    private var categories: [String] {
        Array(Set(gameManager.locations.map { $0.category })).sorted()
    }

    private var activeFilterCount: Int {
        selectedCategories.count + selectedStatuses.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if gameManager.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading locations...")
                            .padding()
                            .foregroundColor(.secondary)
                    }
                } else {
                    Map(position: $mapPosition) {
                        UserAnnotation()

                        ForEach(filteredLocations) { location in
                        Annotation(location.name, coordinate: CLLocationCoordinate2D(
                            latitude: location.coordinates.lat,
                            longitude: location.coordinates.lng
                        )) {
                            LocationMarker(
                                location: location,
                                status: getLocationStatus(location)
                            )
                            .onTapGesture {
                                isAutoTriggered = false
                                selectedLocation = location
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                }

                if !gameManager.isLoading {
                    VStack {
                    HStack {
                        // Filter button with badge
                        Button(action: { showFilters = true }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)

                                // Badge indicator
                                if activeFilterCount > 0 {
                                    Text("\(activeFilterCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                        .padding(.leading)

                        Spacer()

                        // Center on user button
                        Button(action: centerOnUser) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing)
                    }
                    .padding(.top)

                    Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedLocation) { location in
                LocationDetailSheet(location: location, autoTriggered: isAutoTriggered)
                    .environmentObject(gameManager)
                    .environmentObject(locationManager)
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
            .sheet(isPresented: $showFilters) {
                FilterView(
                    categories: categories,
                    selectedCategories: $selectedCategories,
                    selectedStatuses: $selectedStatuses
                )
            }
            .onAppear {
                if let userLoc = locationManager.userLocation {
                    mapPosition = .region(MKCoordinateRegion(
                        center: userLoc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    ))
                }
                // Initial proximity check
                locationManager.checkProximity(to: gameManager.locations)
            }
            .onChange(of: locationManager.userLocation) { _, _ in
                // Check proximity whenever user location updates
                locationManager.checkProximity(to: gameManager.locations)
            }
            .onChange(of: locationManager.enteredLocationId) { _, newLocationId in
                // Auto-popup when user enters a location's range
                if let locationId = newLocationId,
                   let location = gameManager.locations.first(where: { $0.id == locationId }) {
                    isAutoTriggered = true
                    selectedLocation = location
                    locationManager.resetEnteredLocation()
                }
            }
            .onChange(of: jumpToLocationId) { _, locationId in
                // Handle jump to location from progress tab
                if let locationId = locationId,
                   let location = gameManager.locations.first(where: { $0.id == locationId }) {
                    centerOnLocation(location)
                    selectedLocation = location  // Open detail sheet
                    isAutoTriggered = false  // User-initiated jump
                    jumpToLocationId = nil  // Reset after handling
                }
            }
        }
    }

    private func centerOnUser() {
        if let userLocation = locationManager.userLocation {
            withAnimation {
                mapPosition = .region(MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }

    private func centerOnLocation(_ location: LocationData) {
        withAnimation {
            mapPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: location.coordinates.lat,
                    longitude: location.coordinates.lng
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    private func getLocationStatus(_ location: LocationData) -> LocationStatus {
        let isVisited = gameManager.userProgress?.locationsVisited.contains(location.id) ?? false

        if !isVisited {
            return .locked
        }

        let quizzesForLocation = gameManager.getQuizzesForLocation(location.id)
        let completedQuizzes = quizzesForLocation.filter { gameManager.userProgress?.quizzesCompleted.contains($0.id) ?? false }

        if !quizzesForLocation.isEmpty && completedQuizzes.count == quizzesForLocation.count {
            return .completed
        }

        return .unlocked
    }
}

enum LocationStatus: String, CaseIterable, Identifiable {
    case locked = "Locked"
    case unlocked = "In Progress"
    case completed = "Completed"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .locked: return "lock.fill"
        case .unlocked: return "lock.open.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }
}

struct LocationMarker: View {
    let location: LocationData
    let status: LocationStatus

    private var borderColor: Color {
        switch status {
        case .locked:
            return Color(red: 0.75, green: 0.75, blue: 0.75) // Light grey
        case .unlocked:
            return Color(red: 0.2, green: 0.75, blue: 0.4) // Green
        case .completed:
            return Color(red: 0.95, green: 0.75, blue: 0.0) // Gold
        }
    }

    private var badgeColor: Color {
        switch status {
        case .locked:
            return Color(red: 0.6, green: 0.6, blue: 0.6)
        case .unlocked:
            return Color(red: 0.2, green: 0.75, blue: 0.4)
        case .completed:
            return Color(red: 0.95, green: 0.75, blue: 0.0)
        }
    }

    var body: some View {
        ZStack {
            // Outer border ring - colored by status
            Circle()
                .stroke(borderColor, lineWidth: 2)
                .frame(width: 30, height: 30)

            // Background circle - white/light grey for all
            Circle()
                .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
                .frame(width: 26, height: 26)

            // Emoji icon - always visible
            Text(location.emoji)
                .font(.system(size: 14))

            // Lock icon overlay for locked locations
            if status == .locked {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.white)
                            .padding(2)
                            .background(
                                Circle()
                                    .fill(badgeColor)
                                    .frame(width: 11, height: 11)
                            )
                            .offset(x: 1.5, y: 1.5)
                    }
                }
                .frame(width: 26, height: 26)
            }

            // Completion badge for completed locations
            if status == .completed {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(badgeColor)
                                    .frame(width: 11, height: 11)
                            )
                            .offset(x: 1.5, y: 1.5)
                    }
                }
                .frame(width: 26, height: 26)
            }
        }
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

struct FilterView: View {
    let categories: [String]
    @Binding var selectedCategories: Set<String>
    @Binding var selectedStatuses: Set<LocationStatus>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Categories")) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: { toggleCategory(category) }) {
                            HStack {
                                Text(category.capitalized)
                                Spacer()
                                if selectedCategories.contains(category) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                Section(header: Text("Status")) {
                    ForEach(LocationStatus.allCases) { status in
                        Button(action: { toggleStatus(status) }) {
                            HStack {
                                Image(systemName: status.icon)
                                    .foregroundColor(statusColor(status))
                                Text(status.rawValue)
                                Spacer()
                                if selectedStatuses.contains(status) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategories.removeAll()
                        selectedStatuses.removeAll()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    private func toggleStatus(_ status: LocationStatus) {
        if selectedStatuses.contains(status) {
            selectedStatuses.remove(status)
        } else {
            selectedStatuses.insert(status)
        }
    }

    private func statusColor(_ status: LocationStatus) -> Color {
        switch status {
        case .locked: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .unlocked: return Color(red: 0.2, green: 0.75, blue: 0.4)
        case .completed: return Color(red: 0.95, green: 0.75, blue: 0.0)
        }
    }
}
