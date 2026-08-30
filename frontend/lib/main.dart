import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/color_palette.dart';
import 'package:frontend/models/pod_offline_model.dart';
import 'package:frontend/provider/hive_offline_provider.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/splashscreen.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:workmanager/workmanager.dart';


@pragma('vm:entry-point')
void callbackDispatch(){
  Workmanager().executeTask((task, inputData) async {

    debugPrint("Background Task: $task started");

    WidgetsFlutterBinding.ensureInitialized();

    // Perform your background task here
    await Hive.initFlutter();
    if(!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PodModelAdapter());
    }
    await Hive.openBox<PodModel>('pendingPods');

    await NotificationService.initialize();

    final uploader = PendingPodUploader();
    final uploadedReq = await uploader.uploadPendingPods();

   
    for (var req in uploadedReq){
      await NotificationService.showNotification(requestNumber: req);
    }
    debugPrint("Background Task: $task completed");
    debugPrint("returned requests: $uploadedReq");
    return Future.value(true);
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  Hive.registerAdapter(PodModelAdapter());
  await Hive.openBox<PodModel>('pendingPods');

  // Request notification permission BEFORE scheduling or showing notifications
  await NotificationService.requestPermission();
  await NotificationService.initialize();

  // Initialize Workmanager
  await Workmanager().initialize(callbackDispatch);

  // Register periodic task (example: every 15 minutes)
  await Workmanager().registerPeriodicTask(
    "uploadPendingPodsTask",
    "uploadPendingPods",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLightTheme = ref.watch(themeProvider);
    return MaterialApp(
      theme: isLightTheme
          ? ThemeData.from(colorScheme: lightColorScheme) // Use light theme
          : ThemeData.from(colorScheme: darkColorScheme), // Use dark theme
      home: const Splashscreen(),
      builder: (context, child) {
        AppTextStyles.init(context);
        return child!;
      }, // Start with the splash screen
      debugShowCheckedModeBanner: false,
    );
  }
}