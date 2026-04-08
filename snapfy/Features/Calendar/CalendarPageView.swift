import AVKit
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private enum MediaSource: Identifiable {
    case camera
    case library

    var id: String {
        switch self {
        case .camera: return "camera"
        case .library: return "library"
        }
    }

    var pickerSourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: return .camera
        case .library: return .photoLibrary
        }
    }
}

private struct SelectedDay: Identifiable {
    let date: Date

    var id: String {
        ISO8601DateFormatter().string(from: date)
    }
}

struct CalendarPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MediaEntry.createdAt, order: .reverse) private var mediaEntries: [MediaEntry]

    @State private var displayedMonth = CalendarDateUtils.startOfMonth(for: .now)
    @State private var selectedDate = Date()
    @State private var showingMediaOptions = false
    @State private var activeSource: MediaSource?
    @State private var presentedMediaDay: SelectedDay?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                monthHeader

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(CalendarDateUtils.weekdaySymbols(), id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(CalendarDateUtils.monthDays(for: displayedMonth), id: \.self) { day in
                        let dayEntries = entries(for: day)

                        CalendarDayCell(
                            day: day,
                            isCurrentMonth: CalendarDateUtils.isInMonth(day, month: displayedMonth),
                            isSelected: CalendarDateUtils.isSameDay(day, selectedDate),
                            thumbnailData: dayEntries.first?.thumbnailData,
                            isVideo: dayEntries.first?.mediaType == "video",
                            isShowingOptions: showingMediaOptions && CalendarDateUtils.isSameDay(day, selectedDate),
                            onTap: {
                                let wasSelectedDay = CalendarDateUtils.isSameDay(day, selectedDate)
                                selectedDate = day

                                if dayEntries.isEmpty {
                                    if wasSelectedDay, showingMediaOptions {
                                        showingMediaOptions = false
                                    } else {
                                        showingMediaOptions = true
                                    }
                                } else {
                                    showingMediaOptions = false
                                    presentedMediaDay = SelectedDay(date: day)
                                }
                            },
                            onSelectCamera: {
                                selectedDate = day
                                openMediaSource(.camera)
                            },
                            onSelectLibrary: {
                                selectedDate = day
                                openMediaSource(.library)
                            }
                        )
                    }
                }

                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingMediaOptions = false
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .onChange(of: displayedMonth) { _, newValue in
            if !CalendarDateUtils.isInMonth(selectedDate, month: newValue) {
                selectedDate = newValue
                showingMediaOptions = false
            }
        }
        .sheet(item: $activeSource, onDismiss: {
            activeSource = nil
        }) { source in
            MediaPickerSheet(source: source) { result in
                handleMediaResult(result, for: selectedDate)
            }
        }
        .sheet(item: $presentedMediaDay) { selectedDay in
            DayMediaViewerSheet(
                date: selectedDay.date,
                entries: entries(for: selectedDay.date),
                onPick: { result in
                    handleMediaResult(result, for: selectedDay.date)
                }
            )
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text(CalendarDateUtils.monthTitle(for: displayedMonth))
                .font(.title3.bold())

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 36)
            }
        }
    }

    private func shiftMonth(by value: Int) {
        displayedMonth = CalendarDateUtils.calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    private func openMediaSource(_ source: MediaSource) {
        showingMediaOptions = false
        activeSource = nil
        activeSource = source
    }

    private func entries(for day: Date) -> [MediaEntry] {
        mediaEntries.filter { CalendarDateUtils.isSameDay($0.date, day) }
    }

    private func handleMediaResult(_ result: MediaPickerResult, for date: Date) {
        switch result {
        case .image(let image):
            saveImage(image, for: date)
        case .video(let url):
            saveVideo(url, for: date)
        }
    }

    private func saveImage(_ image: UIImage, for date: Date) {
        guard let imageData = MediaProcessingUtils.imageData(from: image),
              let thumbnailData = MediaProcessingUtils.thumbnailData(from: image) else {
            return
        }

        let entry = MediaEntry(date: date, imageData: imageData, thumbnailData: thumbnailData, mediaType: "image")
        modelContext.insert(entry)
        try? modelContext.save()
    }

    private func saveVideo(_ url: URL, for date: Date) {
        guard let videoData = MediaProcessingUtils.videoData(from: url),
              let thumbnailData = MediaProcessingUtils.videoThumbnailData(from: url) else {
            return
        }

        let entry = MediaEntry(date: date, videoData: videoData, thumbnailData: thumbnailData, mediaType: "video")
        modelContext.insert(entry)
        try? modelContext.save()
    }
}

private struct CalendarDayCell: View {
    let day: Date
    let isCurrentMonth: Bool
    let isSelected: Bool
    let thumbnailData: Data?
    let isVideo: Bool
    let isShowingOptions: Bool
    let onTap: () -> Void
    let onSelectCamera: () -> Void
    let onSelectLibrary: () -> Void

    private let cornerRadius: CGFloat = 14
    private let cellHeight: CGFloat = 88

    var body: some View {
        Button(action: onTap) {
            GeometryReader { proxy in
                let cellSize = proxy.size

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isSelected ? Color.black.opacity(0.14) : Color(.secondarySystemBackground))

                    if let thumbnailData,
                       let image = UIImage(data: thumbnailData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: cellSize.width, height: cellSize.height)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: isSelected ? 2 : 0)

                    Text(CalendarDateUtils.dayNumber(for: day))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(dayNumberColor)
                        .padding(10)

                    if isVideo {
                        Image(systemName: "video.fill")
                            .font(.caption2)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }
                .frame(width: cellSize.width, height: cellSize.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .frame(maxWidth: .infinity, minHeight: cellHeight, maxHeight: cellHeight)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if isShowingOptions {
                CalendarDayActionBubble(
                    date: day,
                    showsCamera: UIImagePickerController.isSourceTypeAvailable(.camera),
                    onSelectCamera: onSelectCamera,
                    onSelectLibrary: onSelectLibrary
                )
                .offset(y: -cellHeight - 10)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .zIndex(isShowingOptions ? 10 : 0)
    }

    private var dayNumberColor: Color {
        if CalendarDateUtils.isToday(day) {
            return .blue
        }

        if Calendar.current.component(.weekday, from: day) == 1 {
            return .red
        }

        return isCurrentMonth ? .primary : Color.secondary.opacity(0.45)
    }

    private var borderColor: Color {
        if isSelected {
            return Color.black.opacity(0.35)
        }

        return .clear
    }
}

private struct CalendarDayActionBubble: View {
    let date: Date
    let showsCamera: Bool
    let onSelectCamera: () -> Void
    let onSelectLibrary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(date.formatted(.dateTime.month().day()))
                .font(.subheadline.weight(.semibold))

            if showsCamera {
                Button(action: onSelectCamera) {
                    Label("카메라", systemImage: "camera")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            Button(action: onSelectLibrary) {
                Label("갤러리", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .frame(width: 170)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .bottom) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundStyle(.thinMaterial)
                .offset(y: 12)
        }
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }
}

private struct DayMediaViewerSheet: View {
    let date: Date
    let entries: [MediaEntry]
    let onPick: (MediaPickerResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var activeSource: MediaSource?
    @State private var selectedIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if entries.isEmpty {
                    ContentUnavailableView("미디어가 없습니다", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            DayMediaPage(entry: entry)
                                .tag(index)
                                .padding(.horizontal, 12)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(maxWidth: .infinity, maxHeight: 440)

                    HStack {
                        Text("\(selectedIndex + 1) / \(entries.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(date.formatted(.dateTime.year().month().day()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 18)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(date.formatted(.dateTime.month().day()))
                        .font(.headline)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button("카메라", systemImage: "camera") {
                                activeSource = .camera
                            }
                        }

                        Button("갤러리", systemImage: "photo.on.rectangle") {
                            activeSource = .library
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(item: $activeSource, onDismiss: {
            activeSource = nil
        }) { source in
            MediaPickerSheet(source: source) { result in
                onPick(result)
            }
        }
        .onChange(of: entries.count) { _, newCount in
            if newCount == 0 {
                selectedIndex = 0
            } else if selectedIndex >= newCount {
                selectedIndex = max(0, newCount - 1)
            } else {
                selectedIndex = 0
            }
        }
    }
}

private struct DayMediaPage: View {
    let entry: MediaEntry

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))

            if entry.mediaType == "video", let data = entry.videoData {
                DayMediaVideoPlayer(entryID: entry.id, videoData: data)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            } else if let data = entry.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct DayMediaVideoPlayer: View {
    let entryID: UUID
    let videoData: Data

    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: entryID) {
            guard let url = MediaProcessingUtils.temporaryVideoURL(from: videoData, id: entryID) else {
                player = nil
                return
            }
            player = AVPlayer(url: url)
        }
        .onDisappear {
            player?.pause()
        }
    }
}

private enum MediaPickerResult {
    case image(UIImage)
    case video(URL)
}

private struct MediaPickerSheet: UIViewControllerRepresentable {
    let source: MediaSource
    let onPick: (MediaPickerResult) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = source.pickerSourceType
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        picker.videoMaximumDuration = 60
        picker.videoQuality = .typeMedium
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onPick: (MediaPickerResult) -> Void
        let dismiss: DismissAction

        init(onPick: @escaping (MediaPickerResult) -> Void, dismiss: DismissAction) {
            self.onPick = onPick
            self.dismiss = dismiss
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onPick(.image(image))
            } else if let videoURL = info[.mediaURL] as? URL {
                onPick(.video(videoURL))
            }
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        CalendarPageView()
            .modelContainer(for: [MediaEntry.self], inMemory: true)
    }
}
