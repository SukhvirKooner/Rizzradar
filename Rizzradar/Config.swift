import Foundation

enum Config {
    // Firebase Configuration
    static let firebaseConfig = [
        "apiKey": "AIzaSyDEb4zZ975ucmwzVLOqSS6kKa_5iDLqEzM",
        "authDomain": "rizzradar-d13ee.firebaseapp.com",
        "projectId": "rizzradar-d13ee",
        "storageBucket": "rizzradar-d13ee.firebasestorage.app",
        "messagingSenderId": "612808084817",
        "appId": "1:612808084817:web:4d75ff1387a60698ce5770",
        "databaseURL": "https://rizzradar-d13ee-default-rtdb.firebaseio.com/"
    ]
    
    // Encryption Keys
    static let groupKeySize = 256 // bits
    static let saltLength = 32 // bytes
    static let iterations = 10000
} 
