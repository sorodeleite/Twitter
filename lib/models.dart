import 'dart:convert';

/// Conta do app: a sua, a de uma amiga ou um bot.
class Account {
  Account({
    required this.id,
    required this.name,
    required this.handle,
    this.bio = '',
    this.location = '',
    this.website = '',
    this.joinedDate = 'novembro de 2026',
    this.avatarEmoji = '♡',
    this.avatarPath,
    this.bannerPath,
    this.bannerColorValue = 0xFF1D9BF0,
    this.verified = false,
    this.isMe = false,
    this.isBot = false,
    this.isFriend = false,
    this.autoInteract = true,
    this.useLowercase = true,
    this.favoriteEmojis = '♡ ✨ 🥺',
    this.styleNotes = '',
    this.personality = '',
    List<String>? replyTemplates,
    List<String>? examplePosts,
    this.followingCount = 12,
    this.followersCount = 24,
  })  : replyTemplates = replyTemplates ?? [],
        examplePosts = examplePosts ?? [];

  final String id;
  String name;
  String handle;
  String bio;
  String location;
  String website;
  String joinedDate;
  String avatarEmoji;
  String? avatarPath;
  String? bannerPath;
  int bannerColorValue;
  bool verified;
  bool isMe;
  bool isBot;
  bool isFriend;
  bool autoInteract;
  bool useLowercase;
  String favoriteEmojis;
  String styleNotes;
  String personality;
  List<String> replyTemplates;
  List<String> examplePosts;
  int followingCount;
  int followersCount;

  bool get isIllit => id == 'illit';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'handle': handle,
        'bio': bio,
        'location': location,
        'website': website,
        'joinedDate': joinedDate,
        'avatarEmoji': avatarEmoji,
        'avatarPath': avatarPath,
        'bannerPath': bannerPath,
        'bannerColorValue': bannerColorValue,
        'verified': verified,
        'isMe': isMe,
        'isBot': isBot,
        'isFriend': isFriend,
        'autoInteract': autoInteract,
        'useLowercase': useLowercase,
        'favoriteEmojis': favoriteEmojis,
        'styleNotes': styleNotes,
        'personality': personality,
        'replyTemplates': replyTemplates,
        'examplePosts': examplePosts,
        'followingCount': followingCount,
        'followersCount': followersCount,
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: j['name'] as String? ?? 'Conta',
        handle: j['handle'] as String? ?? '@conta',
        bio: j['bio'] as String? ?? '',
        location: j['location'] as String? ?? '',
        website: j['website'] as String? ?? '',
        joinedDate: j['joinedDate'] as String? ?? 'novembro de 2026',
        avatarEmoji: j['avatarEmoji'] as String? ?? '♡',
        avatarPath: j['avatarPath'] as String?,
        bannerPath: j['bannerPath'] as String?,
        bannerColorValue: j['bannerColorValue'] as int? ?? 0xFF1D9BF0,
        verified: j['verified'] as bool? ?? false,
        isMe: j['isMe'] as bool? ?? false,
        isBot: j['isBot'] as bool? ?? false,
        isFriend: j['isFriend'] as bool? ?? false,
        autoInteract: j['autoInteract'] as bool? ?? true,
        useLowercase: j['useLowercase'] as bool? ?? true,
        favoriteEmojis: j['favoriteEmojis'] as String? ?? '♡ ✨',
        styleNotes: j['styleNotes'] as String? ?? '',
        personality: j['personality'] as String? ?? '',
        replyTemplates: (j['replyTemplates'] as List?)?.map((e) => e.toString()).toList() ?? [],
        examplePosts: (j['examplePosts'] as List?)?.map((e) => e.toString()).toList() ?? [],
        followingCount: j['followingCount'] as int? ?? 12,
        followersCount: j['followersCount'] as int? ?? 24,
      );
}

class Reply {
  Reply({
    required this.id,
    required this.accountId,
    required this.name,
    required this.handle,
    required this.avatarEmoji,
    this.avatarPath,
    this.verified = false,
    required this.text,
    required this.createdAtMs,
    this.likes = 0,
    this.liked = false,
  });

  final String id;
  String accountId;
  String name;
  String handle;
  String avatarEmoji;
  String? avatarPath;
  bool verified;
  String text;
  int createdAtMs;
  int likes;
  bool liked;

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'name': name,
        'handle': handle,
        'avatarEmoji': avatarEmoji,
        'avatarPath': avatarPath,
        'verified': verified,
        'text': text,
        'createdAtMs': createdAtMs,
        'likes': likes,
        'liked': liked,
      };

  factory Reply.fromJson(Map<String, dynamic> j) => Reply(
        id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        accountId: j['accountId'] as String? ?? 'me',
        name: j['name'] as String? ?? 'Angel',
        handle: j['handle'] as String? ?? '@angel',
        avatarEmoji: j['avatarEmoji'] as String? ?? '♡',
        avatarPath: j['avatarPath'] as String?,
        verified: j['verified'] as bool? ?? false,
        text: j['text'] as String? ?? '',
        createdAtMs: j['createdAtMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        likes: j['likes'] as int? ?? 0,
        liked: j['liked'] as bool? ?? false,
      );
}

class Post {
  Post({
    required this.id,
    required this.accountId,
    required this.name,
    required this.handle,
    required this.avatarEmoji,
    this.avatarPath,
    required this.text,
    required this.createdAtMs,
    this.verified = false,
    this.image,
    this.imageUrl,
    this.linkUrl,
    this.linkTitle,
    this.likes = 0,
    this.reposts = 0,
    this.views = 0,
    this.isBot = false,
    this.pinned = false,
    this.liked = false,
    this.reposted = false,
    this.bookmarked = false,
    this.repostedBy,
    this.replyToId,
    List<Reply>? replies,
  }) : replies = replies ?? [];

  final String id;
  String accountId;
  String name;
  String handle;
  String avatarEmoji;
  String? avatarPath;
  String text;
  int createdAtMs;
  bool verified;
  String? image;
  String? imageUrl;
  String? linkUrl;
  String? linkTitle;
  int likes;
  int reposts;
  int views;
  bool isBot;
  bool pinned;
  bool liked;
  bool reposted;
  bool bookmarked;
  String? repostedBy;
  String? replyToId;
  List<Reply> replies;

  String? get mediaPath => image ?? imageUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'name': name,
        'handle': handle,
        'avatarEmoji': avatarEmoji,
        'avatarPath': avatarPath,
        'text': text,
        'createdAtMs': createdAtMs,
        'verified': verified,
        'image': image,
        'imageUrl': imageUrl,
        'linkUrl': linkUrl,
        'linkTitle': linkTitle,
        'likes': likes,
        'reposts': reposts,
        'views': views,
        'isBot': isBot,
        'pinned': pinned,
        'liked': liked,
        'reposted': reposted,
        'bookmarked': bookmarked,
        'repostedBy': repostedBy,
        'replyToId': replyToId,
        'replies': replies.map((r) => r.toJson()).toList(),
      };

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        accountId: j['accountId'] as String? ?? 'me',
        name: j['name'] as String? ?? 'Conta',
        handle: j['handle'] as String? ?? '@conta',
        avatarEmoji: j['avatarEmoji'] as String? ?? (j['avatar'] as String? ?? '♡'),
        avatarPath: j['avatarPath'] as String?,
        text: j['text'] as String? ?? '',
        createdAtMs: j['createdAtMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        verified: j['verified'] as bool? ?? false,
        image: j['image'] as String?,
        imageUrl: j['imageUrl'] as String?,
        linkUrl: j['linkUrl'] as String?,
        linkTitle: j['linkTitle'] as String?,
        likes: j['likes'] as int? ?? 0,
        reposts: j['reposts'] as int? ?? 0,
        views: j['views'] as int? ?? 0,
        isBot: j['isBot'] as bool? ?? false,
        pinned: j['pinned'] as bool? ?? false,
        liked: j['liked'] as bool? ?? false,
        reposted: j['reposted'] as bool? ?? false,
        bookmarked: j['bookmarked'] as bool? ?? false,
        repostedBy: j['repostedBy'] as String?,
        replyToId: j['replyToId'] as String?,
        replies: (j['replies'] as List?)
                ?.map((e) => Reply.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.fromName,
    required this.fromHandle,
    required this.fromAvatarEmoji,
    this.fromAvatarPath,
    required this.postId,
    required this.preview,
    required this.createdAtMs,
    this.read = false,
  });

  final String id;
  final String type; // like, repost, reply, follow, update
  final String fromName;
  final String fromHandle;
  final String fromAvatarEmoji;
  final String? fromAvatarPath;
  final String postId;
  final String preview;
  final int createdAtMs;
  bool read;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'fromName': fromName,
        'fromHandle': fromHandle,
        'fromAvatarEmoji': fromAvatarEmoji,
        'fromAvatarPath': fromAvatarPath,
        'postId': postId,
        'preview': preview,
        'createdAtMs': createdAtMs,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        type: j['type'] as String? ?? 'like',
        fromName: j['fromName'] as String? ?? 'Amiga',
        fromHandle: j['fromHandle'] as String? ?? '@amiga',
        fromAvatarEmoji: j['fromAvatarEmoji'] as String? ?? '♡',
        fromAvatarPath: j['fromAvatarPath'] as String?,
        postId: j['postId'] as String? ?? '',
        preview: j['preview'] as String? ?? '',
        createdAtMs: j['createdAtMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        read: j['read'] as bool? ?? false,
      );
}

class DmMessage {
  DmMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAtMs,
  });

  final String id;
  final String senderId;
  final String text;
  final int createdAtMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'createdAtMs': createdAtMs,
      };

  factory DmMessage.fromJson(Map<String, dynamic> j) => DmMessage(
        id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        senderId: j['senderId'] as String? ?? 'me',
        text: j['text'] as String? ?? '',
        createdAtMs: j['createdAtMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );
}

const monthsPt = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

String formatCount(int n) {
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1).replaceAll('.', ',')} mi';
  }
  if (n >= 1000) {
    final v = n / 1000;
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1).replaceAll('.', ',')} mil';
  }
  return '$n';
}

String formatCompact(int n) {
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1).replaceAll('.', ',')}M';
  }
  if (n >= 1000) {
    final v = n / 1000;
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1).replaceAll('.', ',')}K';
  }
  return '$n';
}

String formatRelativeTime(int createdAtMs) {
  final diff = DateTime.now().millisecondsSinceEpoch - createdAtMs;
  if (diff < 60000) return 'agora';
  final mins = diff ~/ 60000;
  if (mins < 60) return '${mins} min';
  final hours = mins ~/ 60;
  if (hours < 24) return '${hours} h';
  final days = hours ~/ 24;
  if (days < 7) return '${days} d';
  final dt = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
  if (dt.year == DateTime.now().year) return '${dt.day} de ${monthsPt[dt.month - 1]}';
  return '${dt.day} de ${monthsPt[dt.month - 1]} de ${dt.year}';
}

String formatClock(int createdAtMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatFullDateTime(int createdAtMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
  return '${formatClock(createdAtMs)} · ${dt.day} de ${monthsPt[dt.month - 1]} de ${dt.year}';
}

String encodeJsonList(List<dynamic> items) => jsonEncode(items);
