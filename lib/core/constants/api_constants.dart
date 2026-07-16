class ApiConstants {
  static const baseUrl = "https://fit-traack-movil-gr4-vercel-xpress-pi.vercel.app";

  static const login = "$baseUrl/api/auth/login";
  static const register = "$baseUrl/api/auth/register";
  static const me = "$baseUrl/api/auth/me";
  static const recover = "$baseUrl/api/auth/recuperarpassword";
  static const newPassword = "$baseUrl/api/auth/nuevopassword";

  static const activities = "$baseUrl/api/activities";
  static const usersMe = "$baseUrl/api/users/me";
  static const usersMePhoto = "$baseUrl/api/users/me/photo";
  static const statsMe = "$baseUrl/api/stats/me";
}
