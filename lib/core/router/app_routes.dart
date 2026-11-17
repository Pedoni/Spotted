abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const signUp = '/signup';
  static const channels = '/channels';
  static const channelNew = '/channels/new';
  static const channelDetail = '/c/:slug';
  static const spotNew = '/c/:slug/spot/new';
  static const newsNew = '/c/:slug/news/new';
  static const eventNew = '/c/:slug/event/new';
  static const eventDetail = '/events/:id';
  static const eventEdit = '/events/:id/edit';
  static const upcomingEvents = '/upcoming-events';
  static const latestNews = '/latest-news';
  static const newsDetail = '/news/:id';
  static const newsEdit = '/news/:id/edit';
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
  static String eventNewPath(String slug) => '/c/$slug/event/new';
  static String eventPath(String id) => '/events/$id';
  static String eventEditPath(String id) => '/events/$id/edit';
  static String newsNewPath(String slug) => '/c/$slug/news/new';
  static String newsPath(String id) => '/news/$id';
  static String newsEditPath(String id) => '/news/$id/edit';
  static String channelModerationPath(String slug) => '/c/$slug/moderation';
  static String channelEditPath(String slug) => '/c/$slug/edit';
  static String chatPath(String id) => '/chats/$id';
  static String spotPath(String id) => '/spots/$id';
}
