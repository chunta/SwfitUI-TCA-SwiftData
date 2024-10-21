import ComposableArchitecture
import SwiftUI

extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        setContentHuggingPriority(.defaultLow, for: .vertical)
    }
}

struct AddToDoView: View {
    @Bindable var store: StoreOf<AddToDoFeature>

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()

    // Constant for corner radius
    private let cornerRadius: CGFloat = 5
    private let fieldHeight: CGFloat = 40

    @State private var showDatePicker = false
    @State private var selectedDate = Date()

    enum ToDoStatus: String, CaseIterable {
        case pending = "Pending"
        case inProgress = "InProgress"
        case completed = "Completed"
    }

    @State private var selectedStatus: ToDoStatus = .pending
    @State private var tag = ""

    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2021, month: 1, day: 1)
        let endComponents = DateComponents(year: 2021, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        let startDate = calendar.date(from: startComponents)!
        let endDate = calendar.date(from: endComponents)!
        return startDate ... endDate
    }()

    var body: some View {
        VStack(spacing: 12) {
            TextField("Enter To-Do Title", text: $store.todo.title.sending(\.setTitle))
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(cornerRadius)
                .padding(.horizontal)

            HStack {
                TextField("Deadline", text: Binding(
                    get: { store.todo.deadline },
                    set: { _ in }
                ))
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(cornerRadius)
                .disabled(true)

                Button(action: {
                    showDatePicker.toggle()
                }) {
                    Image(systemName: "calendar")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(5)
                }
            }
            .padding(.horizontal)

            if showDatePicker {
                DatePicker("Select Deadline",
                           selection: Binding<Date>(
                               get: {
                                   dateFormatter.date(from: store.todo.deadline) ?? Date()
                               },
                               set: { newDate in
                                   let formattedDate = dateFormatter.string(from: newDate)
                                   store.send(.setDeadline(formattedDate))
                                   selectedDate = newDate
                               }
                           ),
                           in: dateRange,
                           displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .frame(height: 250)
                    .padding(.horizontal)
            }

            // Status Picker with Icon
            HStack {
                Image(systemName: "flag.fill")
                    .resizable()
                    .padding(.trailing, 8)
                    .frame(width: 20, height: 12)

                Picker("", selection: $selectedStatus) {
                    ForEach(ToDoStatus.allCases, id: \.self) { status in
                        Text(status.rawValue)
                            .tag(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(height: 40)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 20)

            // Tags Field with Tag Icon
            HStack {
                Image(systemName: "tag.fill")
                    .resizable()
                    .padding(.trailing, 8)
                    .frame(width: 20, height: 12)

                TextField("Enter Tag", text: $tag)
                    .padding(10)
                    .background(Color(.systemGray5))
                    .cornerRadius(cornerRadius)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    store.send(.saveButtonTapped)
                } label: {
                    Text("Add")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(cornerRadius)
                }

                Button {
                    store.send(.cancelButtonTapped)
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(cornerRadius)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)

            Spacer()
        }
        .padding()
        .navigationTitle("Add To-Do")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        AddToDoView(
            store: Store(
                initialState: AddToDoFeature.State(
                    todo: ToDoItem(id: 0, title: "", deadline: "", createdAt: "", updatedAt: "")
                )
            ) {
                AddToDoFeature()
            }
        )
    }
}
