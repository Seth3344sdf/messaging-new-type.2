import 'package:flutter/material.dart';

enum Presence { online, idle, offline }

class AppUser {
  final String id;
  final String name;
  final String avatarId;
  final Presence presence;
  final String? status;
  final bool isAi;

  const AppUser({
    required this.id,
    required this.name,
    required this.avatarId,
    this.presence = Presence.offline,
    this.status,
    this.isAi = false,
  });

  AppUser copyWith({
    String? name,
    String? avatarId,
    Presence? presence,
    String? status,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      presence: presence ?? this.presence,
      status: status ?? this.status,
      isAi: isAi,
    );
  }

  Color get presenceColor {
    switch (presence) {
      case Presence.online:
        return const Color(0xFF81B29A);
      case Presence.idle:
        return const Color(0xFFF2CC8F);
      case Presence.offline:
        return const Color(0xFFB8AEA3);
    }
  }
}
