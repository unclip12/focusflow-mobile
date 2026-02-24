// =============================================================
// UserProfile — matches types.ts
// =============================================================

class UserProfile {
  final String? displayName;
  final List<String>? searchHistory;

  const UserProfile({this.displayName, this.searchHistory});

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        displayName: j['displayName'],
        searchHistory: j['searchHistory'] != null ? List<String>.from(j['searchHistory']) : null,
      );

  Map<String, dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName,
        if (searchHistory != null) 'searchHistory': searchHistory,
      };

  UserProfile copyWith({String? displayName, List<String>? searchHistory}) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        searchHistory: searchHistory ?? this.searchHistory,
      );
}
