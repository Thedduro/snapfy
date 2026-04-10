import SwiftUI

struct DayMediaViewerSheet: View {
    let date: Date
    let entries: [WorkspaceMediaItem]
    let onPick: (MediaPickerResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var activeSource: MediaSource?
    
    // Tracks the current index of the top card
    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            // Soft gradient spatial background + blur
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.15),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(12)
                            .background(.ultraThickMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.year().month().day()))
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Text(entries.isEmpty ? "미디어가 없습니다" : "\((currentIndex % entries.count) + 1) / \(entries.count)")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
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
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(12)
                            .background(.ultraThickMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)

                if entries.isEmpty {
                    Spacer()
                    ContentUnavailableView("미디어가 없습니다", systemImage: "photo.on.rectangle.angled")
                    Spacer()
                } else {
                    Spacer()
                    // Endless 3D Card Stack
                    ZStack {
                        if !entries.isEmpty {
                            let stackDepth = min(4, entries.count)
                            let upperBound = currentIndex + stackDepth
                            
                            ForEach((currentIndex..<upperBound).reversed(), id: \.self) { absoluteIndex in
                                let mappedIndex = absoluteIndex % entries.count
                                let entry = entries[mappedIndex]
                                
                                Swipeable3DCard(
                                    entry: entry,
                                    index: absoluteIndex,
                                    currentIndex: $currentIndex,
                                    totalCount: upperBound
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Spacer()
                }
            }
        }
        .presentationBackground(.clear)
        .sheet(item: $activeSource, onDismiss: {
            activeSource = nil
        }) { source in
            MediaPickerSheet(source: source) { result in
                onPick(result)
            }
        }
        .onChange(of: entries.count) { _, newCount in
            if newCount == 0 || currentIndex >= newCount {
                currentIndex = 0
            }
        }
    }
}

private struct Swipeable3DCard: View {
    let entry: WorkspaceMediaItem
    let index: Int
    @Binding var currentIndex: Int
    let totalCount: Int
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        let isTopCard = index == currentIndex
        let relativeIndex = index - currentIndex
        
        let scale = max(0.8, 1.0 - CGFloat(relativeIndex) * 0.05)
        let verticalOffset = CGFloat(relativeIndex) * 25.0
        let rotationDegrees = Double(dragOffset.width / 15.0)
        let opacity = relativeIndex > 2 ? 0.0 : 1.0 - Double(relativeIndex) * 0.2

        DayMediaPage(entry: entry)
            .offset(x: isTopCard ? dragOffset.width : 0, 
                    y: isTopCard ? dragOffset.height + verticalOffset : verticalOffset)
            .scaleEffect(isTopCard ? 1.0 : scale)
            .rotationEffect(.degrees(isTopCard ? rotationDegrees : 0), anchor: .bottom)
            .opacity(opacity)
            .zIndex(Double(totalCount - index))
            // 3D Parallax Perspective
            .rotation3DEffect(
                .degrees(isTopCard ? Double(dragOffset.height / 20.0) : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(CGFloat(relativeIndex) * 5.0),
                axis: (x: 1, y: 0, z: 0)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 15)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: relativeIndex)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if isTopCard {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if isTopCard {
                            let threshold: CGFloat = 120
                            let isSwipedOff = abs(dragOffset.width) > threshold || abs(dragOffset.height) > threshold
                            
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                                if isSwipedOff {
                                    let flyOutX = dragOffset.width > 0 ? 500 : -500
                                    let flyOutY = dragOffset.height > 0 ? 800 : -800
                                    dragOffset = CGSize(width: dragOffset.width > 0 ? flyOutX : -flyOutX, 
                                                        height: dragOffset.height > 0 ? flyOutY : -flyOutY)
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        currentIndex += 1
                                        dragOffset = .zero
                                    }
                                } else {
                                    dragOffset = .zero
                                }
                            }
                        }
                    }
            )
    }
}

private struct DayMediaPage: View {
    let entry: WorkspaceMediaItem

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
            
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.6))

            if entry.mediaType == "video", let url = URL(string: entry.originalURL) {
                // To display video, you might want to use a shared VideoPlayer component if defined externally.
                // Assuming DayMediaVideoPlayer was kept in CalendarPageView.swift and is accessible (non-private or internal).
                // If it is private inside CalendarPageView, we must create a local alias or use VideoPlayer here directly.
                // Since I did not share DayMediaVideoPlayer, I will redefine it locally to keep it isolated or depend on standard.
                DayMediaVideoPlayer(videoURL: url)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            } else if let url = URL(string: entry.originalURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    case .failure:
                        ContentUnavailableView("이미지를 불러올 수 없습니다", systemImage: "photo")
                    default:
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView()
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            }
            
            // Glass overlay border for art frame effect
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .frame(width: UIScreen.main.bounds.width - 60, height: UIScreen.main.bounds.height * 0.6)
    }
}

import AVKit

private struct DayMediaVideoPlayer: View {
    let videoURL: URL
    @State private var player = AVPlayer()

    var body: some View {
        VideoPlayer(player: player)
            .task(id: videoURL) {
                player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
            }
            .onDisappear {
                player.pause()
            }
    }
}
