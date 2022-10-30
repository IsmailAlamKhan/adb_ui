import 'package:github/github.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final githubProvider = Provider<GitHub>((ref) => GitHub());
