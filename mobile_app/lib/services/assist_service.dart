// =============================================================
// SafeStreet
// Assist Service
//
// kDeveloperMode: when true, the AssistFeedScreen filters the
// alert list to show only the current user's own alerts.
// Set to false before production or multi-user demos.
//
// Note: getActiveAlerts() and acceptAlert() were previously
// duplicated here. They are now consolidated in AlertService.
// =============================================================

// DEVELOPMENT MODE
// Set to false before production/demo with multiple users.
const bool kDeveloperMode = true;