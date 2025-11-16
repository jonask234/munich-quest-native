import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView {
                    VStack(spacing: 25) {
                        Text("Join Munich Quest!")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 30)
                        
                        VStack(spacing: 15) {
                            TextField("Username", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textContentType(.username)
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)

                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textContentType(.emailAddress)
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)

                            SecureField("Password", text: $password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)

                            SecureField("Confirm Password", text: $confirmPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        if showError {
                            Text(errorText)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        Button(action: handleSignup) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(authManager.isLoading || !isFormValid)
                        
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
    
    private var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }
    
    private func handleSignup() {
        showError = false
        
        if password != confirmPassword {
            errorText = "Passwords do not match"
            showError = true
            return
        }
        
        if password.count < 6 {
            errorText = "Password must be at least 6 characters"
            showError = true
            return
        }
        
        Task {
            let result = await authManager.signUp(username: username, email: email, password: password)
            if case .success = result {
                dismiss()
            } else if let error = authManager.errorMessage {
                errorText = error
                showError = true
            }
        }
    }
}
