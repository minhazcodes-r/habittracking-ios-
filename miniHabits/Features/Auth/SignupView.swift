import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("MiniHabits").font(.titleLarge).foregroundColor(.white)
                        Text("Start tracking your habits today").font(.caption2).foregroundColor(.mutedForeground)
                    }.padding(.top, 60)

                    VStack(spacing: 16) {
                        if let configError = authStore.configurationError {
                            Text(configError).font(.caption2).foregroundColor(.destructive)
                        }
                        if !error.isEmpty {
                            Text(error).font(.caption2).foregroundColor(.destructive)
                        }
                        InputField(placeholder: "Your name", text: $name, label: "Name")
                        InputField(placeholder: "you@example.com", text: $email, label: "Email")
                        InputField(placeholder: "••••••••", text: $password, label: "Password", isSecure: true)

                        Button { Task {
                            let err = await authStore.signup(name: name, email: email, password: password)
                            error = err ?? ""
                        }} label: {
                            Text("Create Account").frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color.white).foregroundColor(.black)
                                .cornerRadius(12).fontWeight(.medium)
                        }
                    }

                    HStack { Rectangle().frame(height: 1).foregroundColor(.borderColor)
                        Text("or").font(.caption2).foregroundColor(.mutedForeground)
                        Rectangle().frame(height: 1).foregroundColor(.borderColor)
                    }

                    Button { Task {
                        let err = await authStore.loginWithGoogle()
                        error = err ?? ""
                    }} label: {
                        Text("Continue with Google").frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.secondaryBg).foregroundColor(.white)
                            .cornerRadius(12).fontWeight(.medium)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderColor))
                    }
                }.padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
    }
}
