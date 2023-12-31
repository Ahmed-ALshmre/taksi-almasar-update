import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emart_customer/AppGlobal.dart';
import 'package:emart_customer/constants.dart';
import 'package:emart_customer/main.dart';
import 'package:emart_customer/model/User.dart';
import 'package:emart_customer/services/FirebaseHelper.dart';
import 'package:emart_customer/services/helper.dart';
import 'package:emart_customer/services/localDatabase.dart';
import 'package:emart_customer/ui/Language/language_choose_screen.dart';
import 'package:emart_customer/ui/QrCodeScanner/QrCodeScanner.dart';
import 'package:emart_customer/ui/StoreSelection/StoreSelection.dart';
import 'package:emart_customer/ui/auth/AuthScreen.dart';
import 'package:emart_customer/ui/cartScreen/CartScreen.dart';
import 'package:emart_customer/ui/chat_screen/inbox_driver_screen.dart';
import 'package:emart_customer/ui/chat_screen/inbox_screen.dart';
import 'package:emart_customer/ui/cuisinesScreen/CuisinesScreen.dart';
import 'package:emart_customer/ui/dineInScreen/dine_in_screen.dart';
import 'package:emart_customer/ui/dineInScreen/my_booking_screen.dart';
import 'package:emart_customer/ui/home/HomeScreen.dart';
import 'package:emart_customer/ui/home/favourite_item.dart';
import 'package:emart_customer/ui/home/favourite_store.dart';
import 'package:emart_customer/ui/mapView/MapViewScreen.dart';
import 'package:emart_customer/ui/ordersScreen/OrdersScreen.dart';
import 'package:emart_customer/ui/privacy_policy/privacy_policy.dart';
import 'package:emart_customer/ui/profile/ProfileScreen.dart';
import 'package:emart_customer/ui/referral_screen/referral_screen.dart';
import 'package:emart_customer/ui/searchScreen/SearchScreen.dart';
import 'package:emart_customer/ui/termsAndCondition/terms_and_codition.dart';
import 'package:emart_customer/ui/wallet/walletScreen.dart';
import 'package:emart_customer/userPrefrence.dart';
import 'package:emart_customer/utils/DarkThemeProvider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_keyhash/flutter_facebook_keyhash.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

enum DrawerSelection {
  Dashboard,
  Home,
  Wallet,
  dineIn,
  Cuisines,
  Search,
  Cart,
  referral,
  Profile,
  Orders,
  MyBooking,
  chooseLanguage,
  inbox,
  driver,
  Logout,
  termsCondition,
  privacyPolicy,
  LikedStore,
  LikedProduct
}

class ContainerScreen extends StatefulWidget {
  final User? user;
  final Widget currentWidget;
  final String vendorId;
  final String appBarTitle;
  final DrawerSelection drawerSelection;

  ContainerScreen({Key? key, required this.user, currentWidget, vendorId, appBarTitle, this.drawerSelection = DrawerSelection.Home})
      : appBarTitle = appBarTitle ?? 'Home'.tr(),
        vendorId = vendorId ?? "",
        currentWidget = currentWidget ??
            HomeScreen(
              user: MyAppState.currentUser,
              vendorId: vendorId,
            ),
        super(key: key);

  @override
  _ContainerScreen createState() {
    return _ContainerScreen();
  }
}

class _ContainerScreen extends State<ContainerScreen> {
  var key = GlobalKey<ScaffoldState>();

  late CartDatabase cartDatabase;
  late String _appBarTitle;
  final fireStoreUtils = FireStoreUtils();

  late Widget _currentWidget;
  late DrawerSelection _drawerSelection;

  int cartCount = 0;
  bool? isWalletEnable;
  late User user;

  Future<void> getKeyHash() async {
    String keyHash;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      keyHash = await FlutterFacebookKeyhash.getFaceBookKeyHash ?? 'Unknown platform KeyHash';
    } on PlatformException {
      keyHash = 'Failed to get Kay Hash.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      keyHash;
      print("::::KEYHASH::::");
      print(keyHash);
    });
  }

  @override
  void initState() {
    FireStoreUtils.getWalletSettingData();
    fireStoreUtils.getplaceholderimage().then((value) {
      AppGlobal.placeHolderImage = value;
    });
    if (widget.user != null) {
      user = widget.user!;
    } else {
      user = User();
    }
    super.initState();
    //FireStoreUtils.walletSettingData().then((value) => isWalletEnable = value);
    _currentWidget = widget.currentWidget;
    _appBarTitle = widget.appBarTitle;
    _drawerSelection = widget.drawerSelection;
    //getKeyHash();
    /// On iOS, we request notification permissions, Does nothing and returns null on Android
    FireStoreUtils.firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cartDatabase = Provider.of<CartDatabase>(context);
  }

  DateTime pre_backpress = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        if (_currentWidget is! HomeScreen) {
          setState(() {
            _drawerSelection = DrawerSelection.Home;
            _appBarTitle = 'Restaurants'.tr();
            _currentWidget = HomeScreen(
              user: MyAppState.currentUser,
            );
          });
          return false;
        } else {
          pushAndRemoveUntil(context, const StoreSelection(), false);
          return true;
        }
      },
      child: ChangeNotifierProvider.value(
        value: user,
        child: Consumer<User>(builder: (context, user, _) {
          return Scaffold(
            extendBodyBehindAppBar: _drawerSelection == DrawerSelection.Wallet ? true : false,
            key: key,
            drawer: Drawer(
              child: Container(
                  color: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : null,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            Consumer<User>(builder: (context, user, _) {
                              return DrawerHeader(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    displayCircleImage(user.profilePictureURL, 75, false),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  user.fullName(),
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ),
                                              Padding(
                                                  padding: const EdgeInsets.only(top: 5.0),
                                                  child: Text(
                                                    user.email,
                                                    style: const TextStyle(color: Colors.white),
                                                  )),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            !themeChange.darkTheme ? const Icon(Icons.light_mode_sharp) : const Icon(Icons.nightlight),
                                            Switch(
                                              // thumb color (round icon)
                                              splashRadius: 50.0,
                                              activeThumbImage: const AssetImage('https://lists.gnu.org/archive/html/emacs-devel/2015-10/pngR9b4lzUy39.png'),
                                              inactiveThumbImage: const AssetImage('http://wolfrosch.com/_img/works/goodies/icon/vim@2x'),

                                              value: themeChange.darkTheme,
                                              onChanged: (value) => setState(() => themeChange.darkTheme = value),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                decoration: BoxDecoration(
                                  color: Color(COLOR_PRIMARY),
                                ),
                              );
                            }),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.Dashboard,
                                title: const Text('Dashboard').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  pushAndRemoveUntil(context, const StoreSelection(), false);
                                },
                                leading: Image.asset(
                                  'assets/images/dashboard.png',
                                  color: _drawerSelection == DrawerSelection.Cuisines
                                      ? Color(COLOR_PRIMARY)
                                      : isDarkMode(context)
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade600,
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.Home,
                                title: const Text('Stores').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _drawerSelection = DrawerSelection.Home;
                                    _appBarTitle = 'Stores'.tr();
                                    _currentWidget = HomeScreen(
                                      user: MyAppState.currentUser,
                                    );
                                  });
                                },
                                leading: const Icon(CupertinoIcons.home),
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.Cuisines,
                                  leading: Image.asset(
                                    'assets/images/category.png',
                                    color: _drawerSelection == DrawerSelection.Cuisines
                                        ? Color(COLOR_PRIMARY)
                                        : isDarkMode(context)
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade600,
                                    width: 24,
                                    height: 24,
                                  ),
                                  title: const Text('Categories').tr(),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.Cuisines;
                                      _appBarTitle = 'Categories'.tr();
                                      _currentWidget = const CuisinesScreen();
                                    });
                                  }),
                            ),
                            Visibility(
                              visible: isDineEnable,
                              child: ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: Color(COLOR_PRIMARY),
                                child: ListTile(
                                    selected: _drawerSelection == DrawerSelection.dineIn,
                                    leading: const Icon(Icons.restaurant),
                                    title: const Text('Dine-in').tr(),
                                    onTap: () {
                                      Navigator.pop(context);

                                      setState(() {
                                        _drawerSelection = DrawerSelection.dineIn;
                                        _appBarTitle = 'Dine-In'.tr();
                                        _currentWidget = DineInScreen(
                                          user: MyAppState.currentUser!,
                                        );
                                      });
                                    }),
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.Search,
                                  title: const Text('Search').tr(),
                                  leading: const Icon(Icons.search),
                                  onTap: () async {
                                    push(context, const SearchScreen());
                                    // Navigator.pop(context);
                                    // setState(() {
                                    //   _drawerSelection = DrawerSelection.Search;
                                    //   _appBarTitle = 'search'.tr();
                                    //   _currentWidget = SearchScreen();
                                    // });
                                    // await Future.delayed(const Duration(seconds: 1), () {
                                    //   setState(() {});
                                    // });
                                  }),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.LikedStore,
                                title: const Text('Favourite Stores').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (MyAppState.currentUser == null) {
                                    push(context, const AuthScreen());
                                  } else {
                                    setState(() {
                                      _drawerSelection = DrawerSelection.LikedStore;
                                      _appBarTitle = 'Favourite Stores'.tr();
                                      _currentWidget = const FavouriteStoreScreen();
                                    });
                                  }
                                },
                                leading: const Icon(CupertinoIcons.heart),
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.LikedProduct,
                                title: const Text('Favourite Item').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (MyAppState.currentUser == null) {
                                    push(context, const AuthScreen());
                                  } else {
                                    setState(() {
                                      _drawerSelection = DrawerSelection.LikedProduct;
                                      _appBarTitle = 'Favourite Item'.tr();
                                      _currentWidget = const FavouriteItemScreen();
                                    });
                                  }
                                },
                                leading: const Icon(CupertinoIcons.heart),
                              ),
                            ),
                            Visibility(
                              visible: UserPreference.getWalletData() ?? false,
                              child: ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: Color(COLOR_PRIMARY),
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.Wallet,
                                  leading: const Icon(Icons.account_balance_wallet_outlined),
                                  title: const Text('Wallet').tr(),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (MyAppState.currentUser == null) {
                                      push(context, const AuthScreen());
                                    } else {
                                      setState(() {
                                        _drawerSelection = DrawerSelection.Wallet;
                                        _appBarTitle = 'Wallet'.tr();
                                        _currentWidget = const WalletScreen();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.Cart,
                                leading: const Icon(CupertinoIcons.cart),
                                title: const Text('Cart').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (MyAppState.currentUser == null) {
                                    push(context, const AuthScreen());
                                  } else {
                                    setState(() {
                                      _drawerSelection = DrawerSelection.Cart;
                                      _appBarTitle = 'Your Cart'.tr();
                                      _currentWidget = const CartScreen();
                                    });
                                  }
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.referral,
                                leading: Image.asset(
                                  'assets/images/refer.png',
                                  width: 28,
                                  color: Colors.grey,
                                ),
                                title: const Text('Refer a friend').tr(),
                                onTap: () async {
                                  if (MyAppState.currentUser == null) {
                                    Navigator.pop(context);
                                    push(context, const AuthScreen());
                                  } else {
                                    Navigator.pop(context);
                                    push(context, const ReferralScreen());
                                  }
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.Profile,
                                leading: const Icon(CupertinoIcons.person),
                                title: const Text('profile').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (MyAppState.currentUser == null) {
                                    push(context, const AuthScreen());
                                  } else {
                                    setState(() {
                                      _drawerSelection = DrawerSelection.Profile;
                                      _appBarTitle = 'My Profile'.tr();
                                      _currentWidget = const ProfileScreen();
                                    });
                                  }
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.Orders,
                                leading: Image.asset(
                                  'assets/images/truck.png',
                                  color: _drawerSelection == DrawerSelection.Orders
                                      ? Color(COLOR_PRIMARY)
                                      : isDarkMode(context)
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade600,
                                  width: 24,
                                  height: 24,
                                ),
                                title: const Text('Orders').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (MyAppState.currentUser == null) {
                                    push(context, const AuthScreen());
                                  } else {
                                    setState(() {
                                      _drawerSelection = DrawerSelection.Orders;
                                      _appBarTitle = 'Orders'.tr();
                                      _currentWidget = OrdersScreen();
                                    });
                                  }
                                },
                              ),
                            ),
                            Visibility(
                              visible: isDineEnable,
                              child: ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: Color(COLOR_PRIMARY),
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.MyBooking,
                                  leading: Image.asset(
                                    'assets/images/your_booking.png',
                                    color: _drawerSelection == DrawerSelection.MyBooking
                                        ? Color(COLOR_PRIMARY)
                                        : isDarkMode(context)
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade600,
                                    width: 24,
                                    height: 24,
                                  ),
                                  title: const Text('Dine-In Bookings').tr(),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (MyAppState.currentUser == null) {
                                      push(context, const AuthScreen());
                                    } else {
                                      setState(() {
                                        _drawerSelection = DrawerSelection.MyBooking;
                                        _appBarTitle = 'Dine-In Bookings'.tr();
                                        _currentWidget = const MyBookingScreen();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            Visibility(
                              visible: isLanguageShown,
                              child: ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: Color(COLOR_PRIMARY),
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.chooseLanguage,
                                  leading: Icon(
                                    Icons.language,
                                    color: _drawerSelection == DrawerSelection.chooseLanguage
                                        ? Color(COLOR_PRIMARY)
                                        : isDarkMode(context)
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade600,
                                  ),
                                  title: const Text('Language').tr(),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.chooseLanguage;
                                      _appBarTitle = 'Language'.tr();
                                      _currentWidget = LanguageChooseScreen(
                                        isContainer: true,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.termsCondition,
                                leading: const Icon(Icons.policy),
                                title: const Text('Terms and Condition').tr(),
                                onTap: () async {
                                  push(context, const TermsAndCondition());
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.privacyPolicy,
                                leading: const Icon(Icons.privacy_tip),
                                title: const Text('Privacy policy').tr(),
                                onTap: () async {
                                  push(context, const PrivacyPolicyScreen());
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.inbox,
                                leading: const Icon(CupertinoIcons.chat_bubble_2_fill),
                                title: const Text('Store Inbox').tr(),
                                onTap: () {
                                  if (MyAppState.currentUser == null) {
                                    Navigator.pop(context);
                                    push(context, const AuthScreen());
                                  } else {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.inbox;
                                      _appBarTitle = 'Store Inbox'.tr();
                                      _currentWidget = const InboxScreen();
                                    });
                                  }
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.driver,
                                leading: const Icon(CupertinoIcons.chat_bubble_2_fill),
                                title: const Text('Driver Inbox').tr(),
                                onTap: () {
                                  if (MyAppState.currentUser == null) {
                                    Navigator.pop(context);
                                    push(context, const AuthScreen());
                                  } else {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.driver;
                                      _appBarTitle = 'Driver Inbox'.tr();
                                      _currentWidget = const InboxDriverScreen();
                                    });
                                  }
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.Logout,
                                leading: const Icon(Icons.logout),
                                title: Text((MyAppState.currentUser == null) ? 'Log In'.tr() : 'Log Out'.tr()),
                                onTap: () async {
                                  if (MyAppState.currentUser == null) {
                                    pushAndRemoveUntil(context, const AuthScreen(), false);
                                  } else {
                                    Navigator.pop(context);
                                    //MyAppState.currentUser!.active = false;
                                    MyAppState.currentUser!.lastOnlineTimestamp = Timestamp.now();
                                    MyAppState.currentUser!.fcmToken = "";
                                    await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
                                    await auth.FirebaseAuth.instance.signOut();
                                    MyAppState.currentUser = null;
                                    COLOR_PRIMARY = 0xFF00B761;
                                    MyAppState.selectedPosition = Position.fromMap({'latitude': 0.0, 'longitude': 0.0});
                                    Provider.of<CartDatabase>(context, listen: false).deleteAllProducts();
                                    pushAndRemoveUntil(context, const AuthScreen(), false);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("V : $appVersion"),
                      )
                    ],
                  )),
            ),
            appBar: AppBar(
              elevation: _drawerSelection == DrawerSelection.Wallet ? 0 : 0,
              centerTitle: _drawerSelection == DrawerSelection.Wallet ? true : false,
              backgroundColor: _drawerSelection == DrawerSelection.Wallet
                  ? Colors.transparent
                  : isDarkMode(context)
                      ? _drawerSelection == DrawerSelection.Home
                          ? Colors.black
                          : Colors.black
                      : _drawerSelection == DrawerSelection.Home
                          ? Colors.black
                          : Colors.white,
              //isDarkMode(context) ? Color(DARK_COLOR) : null,
              leading: IconButton(
                  visualDensity: const VisualDensity(horizontal: -4),
                  padding: const EdgeInsets.only(right: 5),
                  icon: Image(
                    image: const AssetImage("assets/images/menu.png"),
                    width: 20,
                    color: _drawerSelection == DrawerSelection.Wallet
                        ? Colors.white
                        : isDarkMode(context) || _drawerSelection == DrawerSelection.Home
                            ? Colors.white
                            : Colors.black,
                  ),
                  onPressed: () => key.currentState!.openDrawer()),
              // iconTheme: IconThemeData(color: Colors.blue),
              title: Text(
                _appBarTitle,
                style: TextStyle(
                    fontSize: 18,
                    color: _drawerSelection == DrawerSelection.Wallet || _drawerSelection == DrawerSelection.Home
                        ? Colors.white
                        : isDarkMode(context)
                            ? Colors.white
                            : Colors.black,
                    //isDarkMode(context) ? Colors.white : Colors.black,
                    fontWeight: FontWeight.normal),
              ),
              actions: _drawerSelection == DrawerSelection.Wallet || _drawerSelection == DrawerSelection.MyBooking
                  ? []
                  : _drawerSelection == DrawerSelection.dineIn
                      ? [
                          IconButton(
                              padding: const EdgeInsets.only(right: 20),
                              visualDensity: const VisualDensity(horizontal: -4),
                              tooltip: 'QrCode'.tr(),
                              icon: Image(
                                image: const AssetImage("assets/images/qrscan.png"),
                                width: 20,
                                color: isDarkMode(context) || _drawerSelection == DrawerSelection.Home ? Colors.white : Colors.black,
                              ),
                              onPressed: () {
                                push(
                                  context,
                                  const QrCodeScanner(
                                    presectionList: [],
                                  ),
                                );
                              }),
                          IconButton(
                              visualDensity: const VisualDensity(horizontal: -4),
                              padding: const EdgeInsets.only(right: 10),
                              icon: Image(
                                image: const AssetImage("assets/images/search.png"),
                                width: 20,
                                color: isDarkMode(context) || _drawerSelection == DrawerSelection.Home ? Colors.white : null,
                              ),
                              onPressed: () {
                                push(context, const SearchScreen());
                              }),
                          if (_currentWidget is! CartScreen || _currentWidget is! ProfileScreen)
                            IconButton(
                              visualDensity: const VisualDensity(horizontal: -4),
                              padding: const EdgeInsets.only(right: 10),
                              icon: Image(
                                image: const AssetImage("assets/images/map.png"),
                                width: 20,
                                color: isDarkMode(context) || _drawerSelection == DrawerSelection.Home ? Colors.white : const Color(0xFF333333),
                              ),
                              onPressed: () => push(
                                context,
                                const MapViewScreen(),
                              ),
                            )
                        ]
                      : [
                          IconButton(
                              padding: const EdgeInsets.only(right: 20),
                              visualDensity: const VisualDensity(horizontal: -4),
                              tooltip: 'QrCode'.tr(),
                              icon: Image(
                                image: const AssetImage("assets/images/qrscan.png"),
                                width: 20,
                                color: isDarkMode(context) || _drawerSelection == DrawerSelection.Home ? Colors.white : Colors.black,
                              ),
                              onPressed: () {
                                push(
                                  context,
                                  const QrCodeScanner(
                                    presectionList: [],
                                  ),
                                );
                              }),
                          IconButton(
                              visualDensity: const VisualDensity(horizontal: -4),
                              padding: const EdgeInsets.only(right: 10),
                              icon: Image(
                                image: const AssetImage("assets/images/search.png"),
                                width: 20,
                                color: isDarkMode(context) || _drawerSelection == DrawerSelection.Home ? Colors.white : null,
                              ),
                              onPressed: () {
                                push(context, const SearchScreen());
                              }),
                          if (_currentWidget is! CartScreen || _currentWidget is! ProfileScreen)
                            IconButton(
                              visualDensity: const VisualDensity(horizontal: -4),
                              padding: const EdgeInsets.only(right: 10),
                              icon: Image(
                                image: const AssetImage("assets/images/map.png"),
                                width: 20,
                                color: isDarkMode(context) || _drawerSelection == DrawerSelection.Home ? Colors.white : const Color(0xFF333333),
                              ),
                              onPressed: () => push(
                                context,
                                const MapViewScreen(),
                              ),
                            ),
                          if (_currentWidget is! CartScreen || _currentWidget is! ProfileScreen)
                            IconButton(
                                padding: const EdgeInsets.only(right: 20),
                                visualDensity: const VisualDensity(horizontal: -4),
                                tooltip: 'Cart'.tr(),
                                icon: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Image(
                                      image: const AssetImage("assets/images/cart.png"),
                                      width: 20,
                                      color: isDarkMode(context) || _drawerSelection == DrawerSelection.Home ? Colors.white : null,
                                    ),
                                    StreamBuilder<List<CartProduct>>(
                                      stream: cartDatabase.watchProducts,
                                      builder: (context, snapshot) {
                                        cartCount = 0;
                                        if (snapshot.hasData) {
                                          for (var element in snapshot.data!) {
                                            cartCount += element.quantity;
                                          }
                                        }
                                        return Visibility(
                                          visible: cartCount >= 1,
                                          child: Positioned(
                                            right: -6,
                                            top: -8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(COLOR_PRIMARY),
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 12,
                                                minHeight: 12,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  cartCount <= 99 ? '$cartCount' : '+99',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    // fontSize: 10,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  ],
                                ),
                                onPressed: () {
                                  if (MyAppState.currentUser == null) {
                                    push(context, const AuthScreen());
                                  } else {
                                    setState(() {
                                      _drawerSelection = DrawerSelection.Cart;
                                      _appBarTitle = 'Your Cart'.tr();
                                      _currentWidget = const CartScreen();
                                    });
                                  }
                                }),
                        ],
            ),
            body: _currentWidget,
          );
        }),
      ),
    );
  }

// Widget _buildSearchField() => TextField(
//       controller: searchController,
//       onChanged: _searchScreenStateKey.currentState == null
//           ? (str) {
//               setState(() {});
//             }
//           : _searchScreenStateKey.currentState!.onSearchTextChanged,
//       textInputAction: TextInputAction.search,
//       decoration: InputDecoration(
//         contentPadding: const EdgeInsets.all(10),
//         isDense: true,
//         fillColor: isDarkMode(context) ? Colors.grey[700] : Colors.grey[200],
//         filled: true,
//         prefixIcon: const Icon(
//           CupertinoIcons.search,
//           color: Colors.black,
//         ),
//         suffixIcon: IconButton(
//             icon: const Icon(
//               CupertinoIcons.clear,
//               color: Colors.black,
//             ),
//             onPressed: () {
//               setState(() {
//                 _searchScreenStateKey.currentState?.clearSearchQuery();
//               });
//             }),
//         focusedBorder: const OutlineInputBorder(
//             borderRadius: BorderRadius.all(
//               Radius.circular(10),
//             ),
//             borderSide: BorderSide(style: BorderStyle.none)),
//         enabledBorder: const OutlineInputBorder(
//             borderRadius: BorderRadius.all(
//               Radius.circular(10),
//             ),
//             borderSide: BorderSide(style: BorderStyle.none)),
//         hintText: tr('Search'),
//       ),
//     );
}
