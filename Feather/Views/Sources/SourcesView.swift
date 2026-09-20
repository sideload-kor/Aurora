//
//  SourcesView.swift
//  Aurora
//

import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews
import NukeUI

struct SourcesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = SourcesViewModel.shared
    @State private var searchText = ""

    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \.AltSource.name, ascending: true)],
        animation: .snappy
    ) private var sources: FetchedResults<AltSource>

    private var filteredSources: [AltSource] {
        sources.filter {
            searchText.isEmpty ||
            ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    header
                    featuredCard

                    if !filteredSources.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(.localized("Repositories"))
                                    .font(.title3.weight(.bold))
                                Spacer()
                                Text("\(filteredSources.count)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(filteredSources) { source in
                                NavigationLink {
                                    SourceAppsView(object: [source], viewModel: viewModel)
                                } label: {
                                    AuroraSourceCard(source: source)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(.localized("Copy"), systemImage: "doc.on.clipboard") {
                                        UIPasteboard.general.string = source.sourceURL?.absoluteString
                                    }
                                    Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
                                        Storage.shared.deleteSource(for: source)
                                    }
                                }
                            }
                        }
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(Color(.systemGroupedBackground))
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .navigationTitle(.localized("Sources"))
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.fetchSources(sources, refresh: true)
            }
        }
        .task(id: Array(sources)) {
            await viewModel.fetchSources(sources)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(.localized("Discover"))
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(.localized("Find apps from your repositories."))
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var featuredCard: some View {
        NavigationLink {
            SourceAppsView(object: Array(sources), viewModel: viewModel)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.orange.gradient)
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 62, height: 62)

                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("All Repositories"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(.localized("Browse everything in one place"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .auroraGlass(cornerRadius: 24, tint: .orange)
        }
        .buttonStyle(.plain)
        .disabled(sources.isEmpty)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "shippingbox")
                .font(.system(size: 42))
                .foregroundStyle(.orange)
            Text(.localized("No Repositories"))
                .font(.title3.weight(.bold))
            Text(.localized("Add a repository to start discovering apps."))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text(.localized("Add repositories from Settings."))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 45)
        .auroraGlass(cornerRadius: 26, tint: .orange)
    }
}

private struct AuroraSourceCard: View {
    let source: AltSource

    var body: some View {
        HStack(spacing: 14) {
            if let url = source.iconURL {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                placeholder
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(source.name ?? .localized("Unknown"))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(source.sourceURL?.absoluteString ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .auroraGlass(cornerRadius: 20, tint: .orange)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.orange.opacity(0.12))
            .frame(width: 52, height: 52)
            .overlay {
                Image(systemName: "globe")
                    .foregroundStyle(.orange)
            }
    }
}

private extension View {
    @ViewBuilder
    func auroraGlass(cornerRadius: CGFloat, tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.tint(tint.opacity(0.12)), in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(tint.opacity(0.14), lineWidth: 0.8)
                }
        }
    }
}
