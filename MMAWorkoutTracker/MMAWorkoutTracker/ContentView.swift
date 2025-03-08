//
//  ContentView.swift
//  MMAWorkoutTracker
//
//  Created by Ebad Rehman on 2025-02-04.
//

//import SwiftUI

//struct ContentView: View {
//    var body: some View {
 //       VStack {
 //           Image(systemName: "globe")
  //              .imageScale(.large)
  //              .foregroundStyle(.tint)
  //          Text("Hello, world!")
  //      }
  //      .padding()
  //  }
//}

//#Preview {
//    ContentView()
//}
import SwiftUI
import Firebase
import UserNotifications

@main
struct MMAWorkoutTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        requestNotificationPermission()
        return true
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            }
        }
    }
}

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false

    var body: some View {
        if isLoggedIn {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            Text("MMA Workout Tracker")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: login) {
                Text("Login")
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if error == nil {
                isLoggedIn = true
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

struct ProfileView: View {
    @State private var totalWorkouts = 0
    @State private var rank = "Beginner"

    var body: some View {
        VStack {
            Text("Your Profile")
                .font(.title)

            Text("Total Workouts: \(totalWorkouts)")

            Text("Rank: \(rank)")

            Button("Refresh") {
                fetchData()
            }
        }
        .onAppear {
            fetchData()
        }
    }

    func fetchData() {
        let user = Auth.auth().currentUser
        if let user = user {
            let ref = Database.database().reference().child("users/\(user.uid)/progress")
            ref.observeSingleEvent(of: .value) { snapshot in
                if let value = snapshot.value as? Int {
                    totalWorkouts = value
                    rank = determineRank(workouts: value)
                }
            }
        }
    }

    func determineRank(workouts: Int) -> String {
        switch workouts {
        case 0..<10: return "Beginner"
        case 10..<30: return "Intermediate"
        default: return "Advanced"
        }
    }
}

struct ProgressView: View {
    @State private var workoutCount = 0

    var body: some View {
        VStack {
            Text("Workouts Completed")
                .font(.title)
            Text("\(workoutCount)")
                .font(.largeTitle)
                .bold()

            Text("Workout of the Day")
                .font(.headline)

            Text(workoutOfTheDay())
                .padding()

            Button("+1 Workout") {
                workoutCount += 1
                saveProgress()
                scheduleNotification()
            }
        }
    }

    func workoutOfTheDay() -> String {
        let workouts = [
            "Practice Double Leg Takedown",
            "Drill Rear Naked Choke",
            "Shadowbox for 10 minutes",
            "Work on Muay Thai footwork",
            "Perform 50 push-ups",
            "Practice Guillotine Choke"
        ]
        return workouts.randomElement() ?? "Rest Day"
    }

    func saveProgress() {
        let user = Auth.auth().currentUser
        if let user = user {
            let ref = Database.database().reference().child("users/\(user.uid)/progress")
            ref.setValue(workoutCount)
        }
    }

    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "MMA Workout Reminder"
        content.body = "Don’t forget to log your workout today!"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
