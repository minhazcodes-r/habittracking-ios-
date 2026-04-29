import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var habitsStore: HabitsStore
    @State private var showCreate = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today").font(.titleLarge).foregroundColor(.white)
                        Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                            .foregroundColor(.mutedForeground)
                    }.padding(.top, 12)

                    if habitsStore.isLoading {
                        Text("Loading...").foregroundColor(.mutedForeground)
                            .frame(maxWidth: .infinity).padding(.top, 40)
                    } else if let error = habitsStore.lastError {
                        Text(error)
                            .foregroundColor(.destructive)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 16)
                    } else if habitsStore.habits.isEmpty {
                        Text("No habits yet. Create one!")
                            .foregroundColor(.mutedForeground)
                            .frame(maxWidth: .infinity).padding(.top, 40)
                    } else {
                        ForEach(habitsStore.habits) { item in
                            NavigationLink(destination: HabitDetailView(habitId: item.id)) {
                                HabitCardView(
                                    item: item,
                                    onDone: {
                                        let isDone = item.current >= item.habit.goal
                                        habitsStore.logProgress(habitId: item.id, value: isDone ? 0 : item.habit.goal)
                                    },
                                    onIncrement: { amt in
                                        let newVal = min(item.current + amt, item.habit.goal)
                                        habitsStore.logProgress(habitId: item.id, value: newVal)
                                    }
                                )
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(.horizontal, 24).padding(.bottom, 80)
            }

            Button { showCreate = true } label: {
                Image(systemName: "plus")
                    .font(.title2).foregroundColor(.black)
                    .frame(width: 56, height: 56)
                    .background(Color.white).clipShape(Circle())
                    .shadow(radius: 8)
            }.padding(24)
        }
        .sheet(isPresented: $showCreate) { CreateHabitView() }
        .task {
            if let uid = authStore.user?.id.uuidString {
                await habitsStore.fetchHabits(userId: uid)
            }
        }
    }
}
