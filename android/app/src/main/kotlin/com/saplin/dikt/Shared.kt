package com.saplin.dikt

// Singleton class to hold global state
object Shared {
    // Property to track if the app has been started
    var appStartedInWindow: Boolean = false
}