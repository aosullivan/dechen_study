import 'web_navigation_stub.dart'
    if (dart.library.html) 'web_navigation_web.dart' as impl;

bool openGatewayToKnowledgePage() => impl.openGatewayToKnowledgePage();
String currentAppPath() => impl.currentAppPath();
void pushAppPath(String path) => impl.pushAppPath(path);
void replaceAppPath(String path) => impl.replaceAppPath(path);
