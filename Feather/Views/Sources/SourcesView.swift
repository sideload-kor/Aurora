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
    @StateObject private var viewModel = SourcesViewModel.shared
    @State private var searchText = ""
    @State private var isAddingSource = false

    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var sources: FetchedResults<AltSource>

    private var filteredSources: [AltSource] {
        guard !searchText.isEmpty else { return Array(sources) }
        return sources.filter { source in
            source.name?.localizedCaseInsensitiveContains(searchText) == true
                || source.sourceURL?.absoluteString.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    hero

                    if sources.isEmpty {
                        emptyState
                    } else {
                        allRepositoriesCard
                        repositoriesSection
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: .localized("Search Repositories")
            )
            .navigationTitle(.localized("Sources"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingSource = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityLabel(.localized("Add Source"))
                }
            }
            .refreshable {
                await viewModel.fetchSources(sources, refresh: true)
            }
            .sheet(isPresented: $isAddingSource) {
                SourcesAddView()
                    .presentationDetents([.medium, .large])
            }
        }
        .tint(.orange)
        .task(id: Array(sources)) {
            await viewModel.fetchSources(sources)
        }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .pink.opacity(0.82)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "sparkles")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(.localized("Discover"))
                    .font(.title2.weight(.bold))
                Text(.localized("Find apps from your repositories."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .auroraGlass(cornerRadius: 24, tint: .orange)
    }

    private var allRepositoriesCard: some View {
        NavigationLink {
            SourceAppsView(object: Array(sources), viewModel: viewModel)
        } label: {
            HStack(spacing: 14) {
                Image("Repositories")
                    .appIconStyle()
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text(.localized("All Repositories"))
                        .font(.headline)
                    Text("\(sources.count) " + .localized("Repositories"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(15)
            .auroraGlass(cornerRadius: 22, tint: .orange)
        }
        .buttonStyle(.plain)
    }

    private var repositoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(.localized("Repositories"))
                    .font(.title3.weight(.bold))
                Spacer()
                Text("\(filteredSources.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if filteredSources.isEmpty {
                Text(.localized("No Repositories"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 28)
                    .auroraGlass(cornerRadius: 20, tint: .orange)
            } else {
                ForEach(filteredSources) { source in
                    NavigationLink {
                        SourceAppsView(object: [source], viewModel: viewModel)
                    } label: {
                        AuroraSourceCard(source: source)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if let url = source.sourceURL?.absoluteString {
                            Button(.localized("Copy"), systemImage: "doc.on.clipboard") {
                                UIPasteboard.general.string = url
                            }
                        }
                        Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
                            Storage.shared.deleteSource(for: source)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 82, height: 82)
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.orange)
            }

            Text(.localized("No Repositories"))
                .font(.title3.weight(.bold))

            Text(.localized("Get started by adding your first repository."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                isAddingSource = true
            } label: {
                Label(.localized("Add Source"), systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
            }
            .buttonStyle(AuroraSourcePrimaryButtonStyle())
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .padding(.horizontal, 20)
        .auroraGlass(cornerRadius: 26, tint: .orange)
    }
}

private struct AuroraSourceCard: View {
    let source: AltSource

    var body: some View {
        HStack(spacing: 13) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                Text(source.name ?? .localized("Unknown"))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(source.sourceURL?.absoluteString ?? .localized("No URL"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(13)
        .auroraGlass(cornerRadius: 20, tint: .orange)
    }

    @ViewBuilder
    private var icon: some View {
        if let url = source.iconURL {
            LazyImage(url: url) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    placeholder
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.orange.opacity(0.12))
            .frame(width: 50, height: 50)
            .overlay {
                Image(systemName: "globe")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
            }
    }
}

private struct AuroraSourcePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color.orange.gradient)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private extension View {
    @ViewBuilder
    func auroraGlass(cornerRadius: CGFloat, tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .regular.tint(tint.opacity(0.10)),
                in: .rect(cornerRadius: cornerRadius)
            )
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
