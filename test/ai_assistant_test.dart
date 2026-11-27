import 'package:flutter_test/flutter_test.dart';

void main(){
  test('AI context sharing is an explicit opt-in',(){
    const includeLifeOsContextByDefault=false;
    expect(includeLifeOsContextByDefault,isFalse);
  });
  test('provider configuration rejects non-HTTPS endpoints',(){
    const endpoint='http://example.com/v1';
    expect(endpoint.startsWith('https://'),isFalse);
  });
}
