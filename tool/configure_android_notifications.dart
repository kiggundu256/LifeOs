import 'dart:io';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('AndroidManifest.xml was not generated. Run flutter create --platforms=android --project-name lifeos . first.');
    exitCode = 1;
    return;
  }
  var content = manifest.readAsStringSync();
  const permission = '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />';
  if (!content.contains(permission)) {
    content = content.replaceFirst('    <application', '$permission\n    <application');
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
  if (!content.contains('ScheduledNotificationBootReceiver')) {
    content = content.replaceFirst('</application>', '$receivers\n    </application>');
  }
  manifest.writeAsStringSync(content);
  stdout.writeln('Android local notification receivers configured.');
}
