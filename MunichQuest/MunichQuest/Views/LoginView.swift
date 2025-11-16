import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView {
                    VStack(spacing: 25) {
                        Text("🏰")
                            .font(.system(size: 60))
                            .padding(.top, 30)
                        
                        Text("Welcome Back!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 15) {
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textContentType(.emailAddress)
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)

                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        if let errorMessage = authManager.errorMessage, showError {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        Button(action: handleLogin) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleLogin() {
        showError = false
        Task {
            let result = await authManager.login(email: email, password: password)
            if case .success = result {
                dismiss()
            } else {
                showError = true
            }
        }
    }
}
