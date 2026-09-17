import SwiftUI

/// Category, minimum rating, and sort — presented together so the user can
/// see and change the whole filter/sort state at once, plus a single Reset.
struct FilterSheet: View {
    @ObservedObject var viewModel: CatalogueViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: categoryBinding) {
                        Text("All categories").tag(String?.none)
                        ForEach(viewModel.availableCategories, id: \.self) { category in
                            Text(category.capitalized).tag(String?.some(category))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Minimum rating") {
                    Stepper(value: $viewModel.minRating, in: 0...5, step: 0.5) {
                        if viewModel.minRating == 0 {
                            Text("Any rating")
                        } else {
                            Text("\(viewModel.minRating, specifier: "%.1f")+ stars")
                        }
                    }
                    .accessibilityValue(viewModel.minRating == 0 ? "Any rating" : "\(viewModel.minRating, specifier: "%.1f") stars and up")
                }

                Section("Sort by") {
                    Picker("Sort by", selection: sortBinding) {
                        ForEach(ProductSortOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if viewModel.hasActiveFilters {
                    Section {
                        Button("Reset all filters", role: .destructive) {
                            Task { await viewModel.resetFilters() }
                        }
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
