
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/screens/reading_screen.dart';

//imports from otzaria
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/models/bookmark.dart';
import 'package:otzaria/screens/bookmark_screen.dart';
import 'package:otzaria/screens/library_browser.dart';
import 'package:otzaria/screens/settings_screen.dart';
import 'package:provider/provider.dart';

class MainWindowView extends StatefulWidget {
  const MainWindowView({Key? key}) : super(key: key);
  @override
  MainWindowViewState createState() => MainWindowViewState();
}

class MainWindowViewState extends State<MainWindowView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  ValueNotifier selectedIndex = ValueNotifier(0);
  final showBookmarksView = ValueNotifier<bool>(false);
  final bookSearchfocusNode = FocusNode();
  final FocusScopeNode mainFocusScopeNode = FocusScopeNode();

  final List<dynamic> rawBookmarks =
      Hive.box(name: 'bookmarks').get('key-bookmarks') ?? [];
  late List<Bookmark> bookmarks;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    bookmarks = rawBookmarks.map((e) => Bookmark.fromJson(e)).toList();

    if (Settings.getValue('key-font-size') == null) {
      Settings.setValue('key-font-size', 25.0);
    }
    if (Settings.getValue('key-font-family') == null) {
      Settings.setValue('key-font-family', 'FrankRuhlCLM');
    }

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<AppModel>(
        builder: (context, appModel, child) => Scaffold(
          body: OrientationBuilder(builder: (context, orientation) {
            Widget mainWindow = Container();
            switch (appModel.currentView) {
              case (0):
                mainWindow = buildLibraryBrowser(appModel);
                break;
              case (1 || 2 || 3):
                mainWindow = const ReadingScreen();
                break;
              case (4):
                mainWindow = buildSettingsScreen();
            }
            if (orientation == Orientation.landscape) {
              return buildHorizontalLayout(mainWindow, appModel);
            } else {
              return Column(children: [
                Expanded(
                  child:
                      Row(children: [buildBookmarksView(appModel), mainWindow]),
                ),
                buildNavigationBottomBar(),
              ]);
            }
          }),
        ),
      ),
    );
  }

  Widget buildHorizontalLayout(Widget mainWindow, AppModel appModel) {
    return Row(children: [
      buildNavigationSideBar(appModel),
      buildBookmarksView(appModel),
      mainWindow
    ]);
  }

  Widget buildLibraryBrowser(AppModel appModel) {
    return Expanded(
      child: Container(color: Colors.white, child: const LibraryBrowser()),
    );
  }

  AnimatedSize buildBookmarksView(AppModel appModel) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: ValueListenableBuilder(
          valueListenable: showBookmarksView,
          builder: (context, showBookmarksView, child) => SizedBox(
                width: showBookmarksView ? 300 : 0,
                height: showBookmarksView ? null : 0,
                child: child!,
              ),
          child: BookmarkView(
            openBookmarkCallBack: appModel.openBook,
            bookmarks: bookmarks,
            closeLeftPaneCallback: closeLeftPanel,
          )),
    );
  }

  Widget buildSettingsScreen() {
    return Expanded(
      child: MySettingsScreen(),
    );
  }

  SizedBox buildNavigationSideBar(AppModel appModel) {
    return SizedBox.fromSize(
      size: const Size.fromWidth(80),
      child: NavigationRail(
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.library_books),
              label: Text('ספריה'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.menu_book),
              label: Text('קריאה'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.bookmark),
              label: Text('סימניות'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.search),
              label: Text('חיפוש'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings),
              label: Text('הגדרות'),
            ),
          ],
          selectedIndex: appModel.currentView,
          onDestinationSelected: (int index) {
            setState(() {
              appModel.currentView = index;
              switch (index) {
                case 2:
                  _openBookmarksScreen();
                case 3:
                  _openSearchScreen(appModel);
              }
            });
          }),
    );
  }

  NavigationBar buildNavigationBottomBar() {
    return NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'ספרייה',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: 'קריאה',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'חיפוש',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark),
            label: 'סימניות',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'הגדרות',
          ),
        ],
        selectedIndex: selectedIndex.value,
        onDestinationSelected: (int index) {
          setState(() {});
        });
  }

  void _openSearchScreen(AppModel appModel) async {
    appModel.addTab(SearchingTab('חיפוש'));
  }

  void _openBookmarksScreen() {
    showBookmarksView.value = !showBookmarksView.value;
  }

  void addBookmark(
      {required String ref, required String title, required int index}) {
    bookmarks.add(Bookmark(ref: ref, title: title, index: index));
    // write to disk
    Hive.box(name: 'bookmarks').put('key-bookmarks', bookmarks);
    // notify user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הסימניה נוספה בהצלחה'),
        ),
      );
    }
  }

  void closeLeftPanel() {
    showBookmarksView.value = false;
  }
}
