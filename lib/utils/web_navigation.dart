import 'web_navigation_stub.dart'
    if (dart.library.html) 'web_navigation_web.dart' as impl;

bool openGatewayToKnowledgePage() => impl.openGatewayToKnowledgePage();
bool openGatewayChapterPage(int chapterNumber) =>
    impl.openGatewayChapterPage(chapterNumber);
bool openExternalUrl(String url) => impl.openExternalUrl(url);
bool isAppDechenStudyHost() => impl.isAppDechenStudyHost();
void leaveAppToDechenStudy() => impl.leaveAppToDechenStudy();
bool hasBrowserBackTarget() => impl.hasBrowserBackTarget();
void navigateBrowserBack() => impl.navigateBrowserBack();
String currentAppPath() => impl.currentAppPath();
void pushAppPath(String path) => impl.pushAppPath(path);
void replaceAppPath(String path) => impl.replaceAppPath(path);
