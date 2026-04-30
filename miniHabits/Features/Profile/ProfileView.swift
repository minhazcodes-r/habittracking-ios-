import SwiftUI
import Supabase

struct ProfileView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var feedbackType: String? = nil
    @State private var feedbackText = ""
    @State private var feedbackSent = false

    private var displayName: String {
        (authStore.user?.userMetadata["full_name"]?.stringValue) ??
        authStore.user?.email?.components(separatedBy: "@").first ?? "User"
    }
    private var displayEmail: String { authStore.user?.email ?? "" }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile").font(.titleLarge).foregroundColor(.white)
                        Text("Manage your account").foregroundColor(.mutedForeground)
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    // User card
                    HStack(spacing: 16) {
                        Image(systemName: "person.fill").font(.title)
                            .frame(width: 64, height: 64).background(Color.white).foregroundColor(.black)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName).font(.title3).fontWeight(.medium).foregroundColor(.white)
                            Text(displayEmail).foregroundColor(.mutedForeground)
                        }
                        Spacer()
                    }
                    .padding(24).background(Color.card).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))

                    // Logout
                    Button { Task { await authStore.logout() } } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(.destructive)
                            Text("Log Out").foregroundColor(.destructive)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.mutedForeground)
                        }
                        .padding(16).background(Color.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))
                    }

                    // Early access + feedback
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("EARLY ACCESS").font(.small).fontWeight(.medium)
                                .foregroundColor(.mutedForeground)
                                .padding(.horizontal, 12).padding(.vertical, 4)
                                .background(Color.secondaryBg).cornerRadius(20)
                            Text("Thanks for being an early user!").font(.bodyMedium).foregroundColor(.white)
                            Text("This app is in its very early releases. Things may break, features may change. Your patience and feedback mean the world.")
                                .font(.caption2).foregroundColor(.mutedForeground).multilineTextAlignment(.center)
                        }

                        HStack(spacing: 8) {
                            FeedbackButton(label: "Report Bug", icon: "ladybug.fill", isSelected: feedbackType == "bug") {
                                feedbackType = "bug"; feedbackSent = false
                            }
                            FeedbackButton(label: "Feedback", icon: "lightbulb.fill", isSelected: feedbackType == "feedback") {
                                feedbackType = "feedback"; feedbackSent = false
                            }
                        }

                        if feedbackType != nil && !feedbackSent {
                            VStack(spacing: 12) {
                                TextField(feedbackType == "bug" ? "Describe the bug..." : "Share your ideas...", text: $feedbackText, axis: .vertical)
                                    .lineLimit(3...6)
                                    .padding(12).background(Color.inputBg).cornerRadius(12).foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderColor))
                                Button { submitFeedback() } label: {
                                    Text("Submit").frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(feedbackText.isEmpty ? Color.white.opacity(0.4) : Color.white)
                                        .foregroundColor(.black).cornerRadius(12).fontWeight(.medium)
                                }.disabled(feedbackText.isEmpty)
                            }
                        }

                        if feedbackSent {
                            Text("Thanks for your feedback! 🙏").font(.caption2).foregroundColor(.green)
                        }

                        Divider().background(Color.borderColor)

                        HStack(spacing: 0) {
                            Text("Built by ").foregroundColor(.mutedForeground)
                            Text("MinhazCodes").foregroundColor(.white)
                        }
                        .font(.caption2)

                        HStack(spacing: 16) {
                            LinkIcon(url: "https://github.com/MinhazCodes-R", icon: "link")
                            LinkIcon(url: "https://www.linkedin.com/in/minhazur-rakin/", icon: "person.2.fill")
                            LinkIcon(url: "https://www.minhazcodes.com/", icon: "globe")
                        }
                    }
                    .padding(24).background(Color.card).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))

                    Text("Version 0.1.0").font(.caption2).foregroundColor(.mutedForeground)
                }.padding(24).padding(.bottom, 80)
            }
        }
    }

    private func submitFeedback() {
        guard let uid = authStore.user?.id.uuidString, !feedbackText.isEmpty else { return }
        let msg = FeedbackMessage(userId: uid, type: feedbackType ?? "feedback", message: feedbackText.trimmingCharacters(in: .whitespaces))
        Task {
            _ = try? await supabase.from("feedback").insert(msg).execute()
            feedbackSent = true; feedbackText = ""
            try? await Task.sleep(for: .seconds(2))
            feedbackSent = false; feedbackType = nil
        }
    }
}

struct FeedbackButton: View {
    let label: String; let icon: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(label).font(.caption2).fontWeight(.medium)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(isSelected ? Color.white : Color.secondaryBg)
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(12)
        }
    }
}

struct LinkIcon: View {
    let url: String; let icon: String
    var body: some View {
        Link(destination: URL(string: url)!) {
            Image(systemName: icon).foregroundColor(.white)
                .frame(width: 40, height: 40).background(Color.secondaryBg).clipShape(Circle())
        }
    }
}
