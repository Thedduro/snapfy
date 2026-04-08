import SwiftUI
import SwiftData
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

struct CalendarPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MediaEntry.createdAt, order: .reverse) private var mediaEntries: [MediaEntry]

    @State private var displayedMonth = CalendarDateUtils.startOfMonth(for: .now)
    @State private var selectedDate = Date()
    @State private var showingMediaOptions = false
    @State private var activeSource: MediaSource?

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
                        CalendarDayCell(
                            day: day,
                            isCurrentMonth: CalendarDateUtils.isInMonth(day, month: displayedMonth),
                            isSelected: CalendarDateUtils.isSameDay(day, selectedDate),
                            thumbnailData: representativeMedia(for: day)?.thumbnailData,
                            isVideo: representativeMedia(for: day)?.mediaType == "video",
                            isShowingOptions: Binding(
                                get: {
                                    showingMediaOptions && CalendarDateUtils.isSameDay(day, selectedDate)
                                },
                                set: { isShowing in
                                    showingMediaOptions = isShowing
                                }
                            ),
                            onTap: {
                                selectedDate = day
                                showingMediaOptions = true
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
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .navigationTitle("캘린더")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: displayedMonth) { _, newValue in
            if !CalendarDateUtils.isInMonth(selectedDate, month: newValue) {
                selectedDate = newValue
            }
        }
        .sheet(item: $activeSource, onDismiss: {
            activeSource = nil
        }) { source in
            MediaPickerSheet(source: source) { result in
                handleMediaResult(result, for: selectedDate)
            }
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

    private func representativeMedia(for day: Date) -> MediaEntry? {
        mediaEntries.first { CalendarDateUtils.isSameDay($0.date, day) }
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
    @Binding var isShowingOptions: Bool
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
                        .fill(isSelected ? Color.blue.opacity(0.12) : Color(.secondarySystemBackground))

                    if let thumbnailData,
                       let image = UIImage(data: thumbnailData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: cellSize.width, height: cellSize.height)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                            .clipped()
                            .overlay(alignment: .bottomTrailing) {
                                if isVideo {
                                    Image(systemName: "video.fill")
                                        .font(.caption2)
                                        .padding(6)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .padding(6)
                                }
                            }
                    }

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: isSelected || CalendarDateUtils.isToday(day) ? 2 : 0)

                    Text(CalendarDateUtils.dayNumber(for: day))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(dayNumberColor)
                        .padding(10)
                }
                .frame(width: cellSize.width, height: cellSize.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .frame(maxWidth: .infinity, minHeight: cellHeight, maxHeight: cellHeight)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingOptions, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            CalendarDayActionPopover(
                date: day,
                showsCamera: UIImagePickerController.isSourceTypeAvailable(.camera),
                onSelectCamera: onSelectCamera,
                onSelectLibrary: onSelectLibrary
            )
            .presentationCompactAdaptation(.popover)
        }
    }

    private var dayNumberColor: Color {
        if CalendarDateUtils.isToday(day) {
            return .blue
        }

        if Calendar.current.component(.weekday, from: day) == 1 {
            return .red
        }

        return isCurrentMonth ? .primary : .tertiary
    }

    private var borderColor: Color {
        if isSelected {
            return .blue
        }

        if CalendarDateUtils.isToday(day) {
            return .accentColor
        }

        return .clear
    }
}

private struct CalendarDayActionPopover: View {
    let date: Date
    let showsCamera: Bool
    let onSelectCamera: () -> Void
    let onSelectLibrary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .padding(14)
        .frame(width: 180)
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
