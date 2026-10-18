import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final report = {...data};
    final name = report.remove('outputName') as String? ?? 'launch_to_new_page';
    await writeResponseData(report, testOutputFilename: name);
  },
);
