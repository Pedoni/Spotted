abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const signUp = '/signup';
  static const channels = '/channels';
  static const channelNew = '/channels/new';
  static const channelDetail = '/c/:slug';
  static const spotNew = '/c/:slug/spot/new';
  static const spotDetail = '/spots/:id';
  static const profile = '/profile';
  static const myChannels = '/profile/channels';
  static const mySpots = '/profile/spots';

  static String channelPath(String slug) => '/c/$slug';
  static String spotNewPath(String slug) => '/c/$slug/spot/new';
  static String spotPath(String id) => '/spots/$id';
}
