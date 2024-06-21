//
//  ProfileView.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/7/24.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var userAuth: Authentication
    @Environment(\.dismiss) var dismiss
    @AppStorage("profile-url") var profileURL: String = ""
    @State var avatarItem: PhotosPickerItem?
    @State var avatarImage: Image = Image(systemName: "person.crop.circle")
    @State var showErrorDownLoading = false
    @State var user: UserInformation?
    var storageService = StorageService.share
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                VStack(alignment: .center) {
                    if profileURL.isEmpty {
                        HStack {
                            Spacer()
                            avatarImage
                                .resizable()
                                .frame(width: 100 , height: 100)
                                .aspectRatio(contentMode: .fit)
                                .clipShape(Circle())
                                .clipped()
                                .padding(4)
                                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            AsyncImage(url: URL(string: profileURL)) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Circle())
                            .clipped()
                            .padding(4)
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                            Spacer()
                        }
                    }
                    PhotosPicker(selection: $avatarItem, matching: .images, photoLibrary: .shared()) {
                        Text("Pick a photo")
                    }
                }
                VStack(alignment: .leading) {
                    Text("Name")
                        .font(.caption)
                    Text(user?.displayName ?? "n/a")
                    Text("Email")
                        .font(.caption)
                    Text(user?.email ?? "n/a")
                }
                .padding([.leading, .trailing])
                Spacer()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
        .onAppear {
            if let user = userAuth.user {
                if let url = user.photoURL {
                    profileURL = url.absoluteString
                }
            }
        }
        .onChange(of: avatarItem) {
            Task {
                if let data = try? await avatarItem?.loadTransferable(type: Image.self) {
                    avatarImage = data
                } else {
                    showErrorDownLoading = true
                }
            }
            if let item = avatarItem {
                storageService.saveImage(item: item)
            }
        }
        .onReceive(storageService.$url) { url in
            if url.isNotEmpty {
                profileURL = url
                Task {
                    await firebaseService.updateAddUserProfileImage(url: url)
                }
            }
        }
        .alert("Error", isPresented: $showErrorDownLoading) {
            Button("Ok", role: .cancel) {
               
            }
        } message: {
            Text("Downloading image")
        }
    }
}

#Preview {
    ProfileView()
}
