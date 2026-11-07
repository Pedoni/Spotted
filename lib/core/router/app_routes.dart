abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const signUp = '/signup';
  static const channels = '/channels';
  static const channelNew = '/channels/new';
  static const channelDetail = '/c/:slug';
  static const profile = '/profile';
  static const myChannels = '/profile/channels';

  static String channelPath(String slug) => '/c/$slug';
}
