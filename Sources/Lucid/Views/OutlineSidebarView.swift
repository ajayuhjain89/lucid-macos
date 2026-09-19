import SwiftUI

public struct OutlineSidebarView: View {
    let headings: [HeadingItem]
    let activeHeadingId: String?
    let onSelectHeading: (String) -> Void
    @State private var searchText = ""

    public init(headings: [HeadingItem], activeHeadingId: String? = nil, onSelectHeading: @escaping (String) -> Void) {
        self.headings = headings
        self.activeHeadingId = activeHeadingId
        self.onSelectHeading = onSelectHeading
    }

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
                ScrollViewReader { proxy in
                    List(filteredHeadings) { heading in
                        let isActive = heading.id == activeHeadingId
                        Button(action: {
                            onSelectHeading(heading.id)
                        }) {
                            HStack(spacing: 6) {
                                Text("H\(heading.level)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(isActive ? Color.accentColor : Color.accentColor.opacity(0.15))
                                    .foregroundColor(isActive ? .white : .accentColor)
                                    .cornerRadius(4)

                                Text(heading.text)
                                    .font(.system(size: 13, weight: isActive ? .semibold : (heading.level <= 2 ? .medium : .regular)))
                                    .foregroundColor(isActive ? .accentColor : .primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .padding(.leading, CGFloat((heading.level - 1) * 12))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 4)
                            .background(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(heading.id)
                    }
                    .listStyle(.sidebar)
                    .onChange(of: activeHeadingId) { _, newId in
                        if let id = newId {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 200, idealWidth: 240)
    }
}
