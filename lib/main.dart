import 'dart:io';
import 'package:app/pages/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
void main() {
  runApp(const IgnifyCareersApp());
}

class IgnifyCareersApp extends StatelessWidget {
  const IgnifyCareersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ignify Careers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF0A2E73),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF449d87),
          primary: const Color(0xFF0A2E73),
          secondary: const Color(0xFF00D26A),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _controller;
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _hasInternet = true;

  final List<String> _urls = [
    "https://www.ignifycareers.com/",
    "https://www.ignifycareers.com/about",
    "https://www.ignifycareers.com/contact",
    "https://www.ignifycareers.com/services",
  ];

  @override
  void initState() {
    super.initState();
    _checkInternet();
    Connectivity().onConnectivityChanged.listen((_) => _checkInternet());

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) async {
            setState(() => _isLoading = false);
            // Inject JS to fix website header
            await _controller.runJavaScript("""
              try {
                var header = document.querySelector('header'); 
                if(header) {
                  var headerBg = window.getComputedStyle(header).backgroundColor;
                  header.style.position = 'fixed';
                  header.style.top = '0';
                  header.style.width = '100%';
                  header.style.zIndex = '9999';
                  header.style.backgroundColor = headerBg;
                }

                // Add top space with same color
                var topSpacer = document.createElement('div');
                topSpacer.style.height = '0px'; // no extra space if needed
                topSpacer.style.width = '100%';
                topSpacer.style.backgroundColor = window.getComputedStyle(header).backgroundColor;
                document.body.prepend(topSpacer);

                var headerHeight = header ? header.offsetHeight : 0;
                document.body.style.paddingTop = headerHeight + 'px';
              } catch(e) {}
            """);
          },
        ),
      )
      ..loadRequest(Uri.parse(_urls[_selectedIndex]));
  }

  Future<void> _checkInternet() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      setState(() => _hasInternet = false);
    } else {
      try {
        final lookup = await InternetAddress.lookup('google.com');
        setState(() =>
        _hasInternet = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty);
      } on SocketException {
        setState(() => _hasInternet = false);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isLoading = true;
    });
    _controller.loadRequest(Uri.parse(_urls[index]));
  }

  Future<void> _reloadPage() async {
    await _checkInternet();
    if (_hasInternet) await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_hasInternet
          ? _buildNoInternetScreen()
          : Stack(
        children: [
          RefreshIndicator(
            onRefresh: _reloadPage,
            color: const Color(0xFF00D26A),
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(
                      color: Color(0xFF00D26A),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Loading...",
                      style: TextStyle(
                        color: Color(0xFF0A2E73),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF449d87),
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house), // professional home icon
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.circleInfo), // info icon
            label: "About",
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.addressBook), // contact icon
            label: "Contact",
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.briefcase), // jobs icon
            label: "Services",
          ),
        ],
      ),
    );
  }

  Widget _buildNoInternetScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Color(0xFF0A2E73)),
            const SizedBox(height: 20),
            const Text(
              "No Internet Connection",
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _reloadPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D26A),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
