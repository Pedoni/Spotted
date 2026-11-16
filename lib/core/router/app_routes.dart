abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const signUp = '/signup';
  static const channels = '/channels';
  static const channelNew = '/channels/new';
  static const channelDetail = '/c/:slug';
  static const spotNew = '/c/:slug/spot/new';
  static const channelModeration = '/c/:slug/moderation';
  static const channelEdit = '/c/:slug/edit';
  static const chats = '/chats';
  static const chatDetail = '/chats/:id';
  static const spotDetail = '/spots/:id';
  static const profile = '/profile';
  static const mySpots = '/profile/spots';
  static const about = '/profile/about';

  static String channelPath(String slug) => '/c/$slug';
  static String spotNewPath(String slug) => '/c/$slug/spot/new';
  static String channelModerationPath(String slug) => '/c/$slug/moderation';
  static String channelEditPath(String slug) => '/c/$slug/edit';
  static String chatPath(String id) => '/chats/$id';
  static String spotPath(String id) => '/spots/$id';
}
