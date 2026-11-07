import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/app.dart';
import 'package:spotted/core/config/env.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/core/supabase/timeout_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
    httpClient: TimeoutClient(),
  );

  runApp(const ProviderScope(retry: noRetry, child: App()));
}
