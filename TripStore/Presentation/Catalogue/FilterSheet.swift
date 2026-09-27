import SwiftUI

/// Category, minimum rating, and sort — presented together so the user can
/// see and change the whole filter/sort state at once, plus a single Reset.
///
/// Visual layout only: every control below reuses the exact same
/// `CatalogueViewModel` bindings/actions the previous Form-based layout used
/// (`categoryBinding`, `sortBinding`, `$viewModel.minRating`,
/// `$viewModel.searchText`, `resetFilters()`, `dismiss()`). "Apply Filters"
/// and "Cancel" both just dismiss — filter changes already apply live as
/// each control is touched, so there is no separate staged/apply step.
struct FilterSheet: View {
    @ObservedObject var viewModel: CatalogueViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            searchRow

            VStack(spacing: 18) {
                filterRow(title: "Sort By") { sortMenu }
                filterRow(title: "Category") { categoryMenu }
                ratingRow
            }

            if viewModel.hasActiveFilters {
                Button("Reset all filters", role: .destructive) {
                    Task { await viewModel.resetFilters() }
                }
                .font(.subheadline.weight(.medium))
            }

            Spacer(minLength: 0)

            applyButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
    }

    private var searchRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search products", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .accessibilityLabel("Search products")
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button("Cancel") { dismiss() }
                .font(.body)
                .accessibilityHint("Closes the filter sheet")
        }
    }

    private func filterRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            content()
        }
    }

    private var sortMenu: some View {
        Picker("Sort by", selection: sortBinding) {
            ForEach(ProductSortOption.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var categoryMenu: some View {
        Picker("Category", selection: categoryBinding) {
            Text("All categories").tag(String?.none)
            ForEach(viewModel.availableCategories, id: \.self) { category in
                Text(category.capitalized).tag(String?.some(category))
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var ratingRow: some View {
        HStack {
            Text("Rating")
                .font(.subheadline.weight(.medium))
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        viewModel.minRating = (viewModel.minRating == Double(star)) ? 0 : Double(star)
                    } label: {
                        Image(systemName: Double(star) <= viewModel.minRating ? "star.fill" : "star")
                            .foregroundStyle(Double(star) <= viewModel.minRating ? .yellow : .secondary)
                    }
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s") and up")
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue(viewModel.minRating == 0 ? "Any rating" : "\(viewModel.minRating, specifier: "%.1f") stars and up")
        }
    }

    private var applyButton: some View {
        Button("Apply Filters") { dismiss() }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(.white)
    }

    private var categoryBinding: Binding<String?> {
        Binding(
            get: { viewModel.selectedCategory },
            set: { newValue in Task { await viewModel.setCategory(newValue) } }
        )
    }

    private var sortBinding: Binding<ProductSortOption> {
        Binding(
            get: { viewModel.sortOption },
            set: { newValue in Task { await viewModel.setSortOption(newValue) } }
        )
    }
}
