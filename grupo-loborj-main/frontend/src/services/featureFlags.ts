export const passwordRequirements = {
  min8: import.meta.env.VITE_PASSWORD_REQUIRE_MIN_8 == "true",
  uppercase: import.meta.env.VITE_PASSWORD_REQUIRE_UPPERCASE == "true",
  number: import.meta.env.VITE_PASSWORD_REQUIRE_NUMBER == "true",
  symbol: import.meta.env.VITE_PASSWORD_REQUIRE_SYMBOL == "true",
}

export const featureFlags = {
  enableNotifications: import.meta.env.VITE_ENABLE_NOTIFICATIONS_FEATURE == "true",
}