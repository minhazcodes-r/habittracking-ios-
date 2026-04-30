import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
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
                        Text("Build better habits, one day at a time").font(.caption2).foregroundColor(.mutedForeground)
                    }.padding(.top, 60)

                    VStack(spacing: 16) {
                        if let configError = authStore.configurationError {
                            Text(configError).font(.caption2).foregroundColor(.destructive)
                        }
                        if !error.isEmpty {
                            Text(error).font(.caption2).foregroundColor(.destructive)
                        }
                        InputField(placeholder: "you@example.com", text: $email, label: "Email")
                        InputField(placeholder: "••••••••", text: $password, label: "Password", isSecure: true)

                        Button { Task {
                            let err = await authStore.login(email: email, password: password)
                            error = err ?? ""
                        }} label: {
                            Text("Log In").frame(maxWidth: .infinity).padding(.vertical, 16)
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

                    HStack(spacing: 4) {
                        Text("Don't have an account?").font(.caption2).foregroundColor(.mutedForeground)
                        NavigationLink("Create Account") { SignupView() }
                            .font(.caption2).foregroundColor(.white)
                    }
                }.padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
    }
}

struct InputField: View {
    let placeholder: String
    @Binding var text: String
    var label: String = ""
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty {
                Text(label).font(.caption2).foregroundColor(.mutedForeground)
            }
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .padding(16)
            .background(Color.inputBg)
            .cornerRadius(12)
            .foregroundColor(.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderColor))
        }
    }
}
