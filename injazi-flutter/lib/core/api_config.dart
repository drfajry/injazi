/// Single source of truth for the backend's base URL. Every screen that
/// creates an ApiService should import this instead of hardcoding the URL
/// — previously it was duplicated across 6 files, which meant a server
/// migration (e.g. changing hosting region) required editing every file
/// individually and risked missing one.
const String kApiBaseUrl = 'https://injazi-backend-frankfurt.onrender.com';
