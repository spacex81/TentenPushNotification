//
//  sendPushNotification.swift
//  PushNotification
//
//  Created by 조윤근 on 6/26/24.
//

import Foundation

func sendPushNotification(to fcmToken: String) {
    guard let url = URL(string: "https://us-central1-tentenios.cloudfunctions.net/sendPushNotification") else {
        print("Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = ["fcmToken": fcmToken]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
    } catch {
        print("Failed to serialize JSON: ", error)
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error sending push notification: ", error)
            return
        }
        
        if let response = response as? HTTPURLResponse {
            print("Response status code: ", response.statusCode)
        }
        
        if let data = data {
            let responseData = String(data: data, encoding: .utf8)
            print("Response data: ", responseData ?? "No data")
        }
    }
    
    task.resume()
}
