import 'dart:io';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('AndroidManifest.xml was not generated. Run flutter create --platforms=android --project-name lifeos . first.');
    exitCode = 1;
    return;
  }
  var xml = manifest.readAsStringSync();
  const permissions = [
    '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />',
    '    <uses-permission android:name="android.permission.INTERNET" />',
  ];
  for (final permission in permissions) {
    final name = permission.split('"')[1];
    if (!xml.contains(name)) {
      xml = xml.replaceFirst('    <application', '$permission\n    <application');
    }
  }
  const receivers = '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>''';
  if (!xml.contains('ScheduledNotificationBootReceiver')) {
    xml = xml.replaceFirst('</application>', '$receivers\n    </application>');
  }
  manifest.writeAsStringSync(xml);

  final kotlinGradle = File('android/app/build.gradle.kts');
  final groovyGradle = File('android/app/build.gradle');
  if (kotlinGradle.existsSync()) {
    var gradle = kotlinGradle.readAsStringSync();
    if (!gradle.contains('isCoreLibraryDesugaringEnabled')) {
      gradle = gradle.replaceFirst('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true');
    }
    gradle = gradle.replaceAll('JavaVersion.VERSION_11', 'JavaVersion.VERSION_17');
    if (!gradle.contains('jvmTarget = JavaVersion.VERSION_17.toString()')) {
      gradle = gradle.replaceFirst('kotlinOptions {', 'kotlinOptions {\n        jvmTarget = JavaVersion.VERSION_17.toString()');
    }
    if (!gradle.contains('multiDexEnabled = true')) {
      gradle = gradle.replaceFirst('defaultConfig {', 'defaultConfig {\n        multiDexEnabled = true');
    }
    if (!gradle.contains('coreLibraryDesugaring(')) {
      if (gradle.contains('dependencies {')) {
        gradle = gradle.replaceFirst('dependencies {', 'dependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")');
      } else {
        gradle += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n';
      }
    }
    kotlinGradle.writeAsStringSync(gradle);
  } else if (groovyGradle.existsSync()) {
    var gradle = groovyGradle.readAsStringSync();
    if (!gradle.contains('coreLibraryDesugaringEnabled true')) {
      gradle = gradle.replaceFirst('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true\n        sourceCompatibility JavaVersion.VERSION_17\n        targetCompatibility JavaVersion.VERSION_17');
    }
    if (!gradle.contains('coreLibraryDesugaring ')) {
      if (gradle.contains('dependencies {')) {
        gradle = gradle.replaceFirst('dependencies {', "dependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'");
      } else {
        gradle += "\n\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n";
      }
    }
    groovyGradle.writeAsStringSync(gradle);
  } else {
    stderr.writeln('Could not find the generated Android app Gradle file.');
    exitCode = 1;
    return;
  }


  const usagePermission = '    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />';
  if (!xml.contains('android.permission.PACKAGE_USAGE_STATS')) {
    xml = xml.replaceFirst('    <application', '$usagePermission\n    <application');
  }
  manifest.writeAsStringSync(xml);

  final activityFiles = Directory('android/app/src/main/kotlin').existsSync()
      ? Directory('android/app/src/main/kotlin').listSync(recursive: true).whereType<File>().where((file) => file.uri.pathSegments.last == 'MainActivity.kt').toList()
      : <File>[];
  if (activityFiles.length != 1) {
    stderr.writeln('Expected one generated MainActivity.kt, found ${activityFiles.length}.');
    exitCode = 1;
    return;
  }
  final activityFile = activityFiles.single;
  final packageMatch = RegExp(r'^package\s+([A-Za-z0-9_.]+)', multiLine: true).firstMatch(activityFile.readAsStringSync());
  if (packageMatch == null) {
    stderr.writeln('Could not determine the generated Android package name.');
    exitCode = 1;
    return;
  }
  final packageName = packageMatch.group(1)!;
  final kotlinTemplate = File('tool/MainActivity.kt.template').readAsStringSync();
  activityFile.writeAsStringSync(kotlinTemplate.replaceAll('@@PACKAGE@@', packageName));

  stdout.writeln('Android notifications, network access, usage monitoring and Java desugaring configured.');
}
