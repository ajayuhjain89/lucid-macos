import SwiftUI

public struct OutlineSidebarView: View {
    let headings: [HeadingItem]
    let onSelectHeading: (String) -> Void
    @State private var searchText = ""

    private var filteredHeadings: [HeadingItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return headings
        }
        return headings.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Filter outline…", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)
            .padding([.horizontal, .top], 12)
            .padding(.bottom, 8)

            Divider()

            if filteredHeadings.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "list.bullet.indent")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(headings.isEmpty ? "No Headings Found" : "No Matches")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(headings.isEmpty ? "Headings will appear here as you write." : "Try a different search term.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(filteredHeadings) { heading in
                    Button(action: {
                        onSelectHeading(heading.id)
                    }) {
                        HStack(spacing: 6) {
                            Text("H\(heading.level)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundColor(.accentColor)
                                .cornerRadius(4)

                            Text(heading.text)
                                .font(.system(size: 13, weight: heading.level <= 2 ? .medium : .regular))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.leading, CGFloat((heading.level - 1) * 12))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }
                .listStyle(.sidebar)
            }
        }
        .frame(minWidth: 200, idealWidth: 240)
    }
}
