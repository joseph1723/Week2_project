import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:goggle_login/user_my_page.dart';
import 'package:http/http.dart' as http;
import 'package:goggle_login/login_platform.dart';
import 'package:goggle_login/point_details_screen.dart';
import 'package:goggle_login/point_list_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'point_list.dart'; // tab1 스크린을 정의한 파일을 import합니다.
import 'user_model.dart';
import 'google_map_screen.dart'; 

class SampleScreen extends StatefulWidget {
  const SampleScreen({super.key});

  @override
  State<SampleScreen> createState() => _SampleScreenState();
}

class _SampleScreenState extends State<SampleScreen> {
  LoginPlatform _loginPlatform = LoginPlatform.none;
  GoogleSignInAccount? _currentUser;

  void signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    _currentUser = googleUser;
    if (googleUser != null) {
      //어디에 띄워?
      print('name = ${googleUser.displayName}');
      print('email = ${googleUser.email}');
      print('id = ${googleUser.id}');

      // 토큰을 이용하여 id를 가져오는 함수 호출
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String token = googleUser.email; // 예시로 email을 token으로 사용

      final userId =
          await getIdByToken(token, googleUser.displayName ?? 'Noname');

      print("This is output userID: ${userId}");
      if (userId != null) {
        Provider.of<UserModel>(context, listen: false)
            .setUser(googleUser, userId);
      }

      // Print the access token
      print('Access token = ${googleAuth.accessToken}');
      print('ID token = ${googleAuth.idToken}');

      if (mounted) {
        setState(() {
          _loginPlatform = LoginPlatform.google;
        });
      }
    }
  }

  Future<String> getIdByToken(String token, String name) async {
    const String baseUrl = 'http://172.10.7.128:80'; // 서버의 기본 URL
    final String url = '$baseUrl/tokenstoid/$token';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var userId = "";
        if (data == null) {
          userId = await tokentoid(token, name);
        } else {
          userId = data['user_id'] as String;
        }
        if (userId != null) {
          print('Returned id: $userId');
          return userId;
        } else {
          print('User id not found.');
          throw Exception('Failed to find user id');
        }
      } else {
        print('Failed to get user id. Status code: ${response.statusCode}');
        throw Exception('Failed to get user id');
      }
    } catch (e) {
      print('Error fetching user id: $e');
      throw Exception('Error fetching user id');
    }
  }

  Future<List<Map<String, dynamic>>> getPointsLists() async {
    String url = 'http://172.10.7.128:80/pointslist/';
    print("Get in getPointsLists");
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        List<Map<String, dynamic>> pointLists =
            data.map((item) => Map<String, dynamic>.from(item)).toList();
        return pointLists;
      } else {
        print(
            'Response not ok with url: $url, status: ${response.statusCode}, statusText: ${response.reasonPhrase}');
        throw Exception('HTTP error! Status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching point lists: $error');
      throw error; // 예외 다시 던지기
    }
  }

  Future<String> tokentoid(String token, String name) async {
    const String url =
        'http://172.10.7.128:80/tokenstoid'; // 포인트를 추가할 엔드포인트 URL

    try {
      final user_id = await createUserLogin(
          name: name,
          email: token,
          id: token.split('@')[0],
          desc: '너의 산책은',
          phoneNumber: '0000000000');
      // 포인트 리스트 생성하기
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'token': token,
          'user_id': user_id,
        }),
      );

      if (response.statusCode == 201) {
        var result = jsonDecode(response.body);
        print('Token added successfully');
        return user_id;
      } else {
        print('Failed to add token. Status code: ${response.statusCode}');
        throw Exception('Failed to add user id');
      }
    } catch (error) {
      print('Error adding token: $error');
      throw Exception('Failed to add user id');
    }
  }

  Future<String> createUserLogin({
    required String name,
    required String email,
    required String id,
    required String desc,
    required String phoneNumber,
  }) async {
    const String url = 'http://172.10.7.128:80/userslogin';

    final userData = {
      'name': name,
      'user_id': id,
      'desc': desc,
      'phoneNumber': phoneNumber,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode != 201) {
        print("url is $url");
        throw Exception('HTTP error! Status: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      print('Created user login: $data');
      return data['user_id'] ?? 'null';
    } catch (error) {
      print('Error creating user login: $error');
      throw Exception('Error creating user login');
    }
  }

  void signOut() async {
    Provider.of<PointListProvider>(context, listen: false).clearPointList();
    Provider.of<UserModel>(context, listen: false).clearUser();
    switch (_loginPlatform) {
      case LoginPlatform.google:
        await GoogleSignIn().signOut();
        break;
      case LoginPlatform.none:
        break;
    }

    setState(() {
      _loginPlatform = LoginPlatform.none;
    });
  }

  //하단바 만들어서 넣기
  void navigateToTab1() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const Tab1Screen()), // Tab1Screen으로 이동합니다.
    );
  }

  void navigateToGoogleMapScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GoogleMapScreen()), // GoogleMapScreen으로 이동합니다.
    );
  }

  void navigateToMyProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MyProfilePage(), // Replace MyProfilePage() with your actual widget instance
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'asset/logo_green.png', // 로고 이미지 파일의 경로
              height: screenHeight * 0.05, // 로고의 높이 (화면 높이에 비례)
            ),
            SizedBox(width: 5), // 로고와 텍스트 사이의 간격
            const Text('산책꼬?'),
          ],
        ),
        backgroundColor: const Color(0xBEF7FF),
        //elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.place),
            onPressed: navigateToTab1,
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: navigateToGoogleMapScreen,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: navigateToMyProfileScreen,
          ),
          if (_loginPlatform != LoginPlatform.none)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: signOut,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('asset/sample_screen_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: _loginPlatform != LoginPlatform.none
              ? _mainContent(context, screenWidth, screenHeight)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.20), // 상단 여백 추가
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: screenHeight * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        
                        children: [
                          Image.asset(
                            'asset/cat2.png',
                            width: 200, // 절대 크기 설정
                            height: 200,
                          ),
                          SizedBox(
                              height: screenHeight * 0.08), // 로그인 버튼과 이미지 사이 간격
                          _loginButton('login', signInWithGoogle),
                          SizedBox(height: screenHeight * 0.1),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _loginButton(String path, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.all(0),
      ),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          image: DecorationImage(
            image: AssetImage('asset/$path.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 294.0, maxHeight: 50.0),
          alignment: Alignment.center,
          child: null,
        ),
      ),
    );
  }

  Widget _mainContent(
      BuildContext context, double screenWidth, double screenHeight) {
    final pointListProvider = Provider.of<PointListProvider>(context);
    final pointList = pointListProvider.pointList;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('asset/sun.png', height: screenHeight * 0.07),
          ],
        ),
        SizedBox(height: screenHeight * 0.03),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: _currentUser?.displayName ?? "User",
                style: TextStyle(
                  color: Color(0xFFA8DF8E),
                  fontSize: screenHeight * 0.03,
                  fontFamily: '교보',
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              TextSpan(
                text: '님 안녕하세요!\n오늘도 즐거운 산책을 시작해볼까요?',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenHeight * 0.025,
                  fontFamily: '교보',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.005),
        Image.asset(
          'asset/장식.png',
          height: screenHeight * 0.12,
        ),
        SizedBox(height: screenHeight * 0.04),
        pointList != null
            ? _buildPointList(pointList)
            : _buildThemeBox(screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildPointList(Map<String, dynamic> pointList) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(
            'Point List',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 30),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              height: 220.0, // Set the desired height here
              child: Row(
                children: pointList['points'].map<Widget>((point) {
                  return Row(
                    children: [
                      _pointBox(point),
                      SizedBox(width: 10), // 박스 사이 간격 추가
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointBox(Map<String, dynamic> point) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PointDetail(point: point),
            ),
          );
        },
        child: Container(
          width: 170,
          height: 210,
          decoration: BoxDecoration(
            color: const Color(0xFFFCFAE9), // 박스의 배경색
            borderRadius: BorderRadius.circular(15), // 모서리 둥글게 만들기
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'asset/places/${point['name']}.png',
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 10), // 이미지와 텍스트 사이의 간격
                Text(
                  point['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  // Widget _buildThemeBox() {
  //   return FutureBuilder<List<Map<String, dynamic>>>(
  //     future: getPointsLists(),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return Center(child: CircularProgressIndicator());
  //       } else if (snapshot.hasError) {
  //         return Center(child: Text('Error: ${snapshot.error}'));
  //       } else if (snapshot.hasData) {
  //         List<Map<String, dynamic>> pointLists = snapshot.data!;
  //         return Column(
  //           children: [
  //             Text(
  //               '오늘의 추천 테마',
  //               style: TextStyle(fontSize: 20),
  //             ),
  //             SizedBox(height: 30),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               children: [
  //                 if (pointLists.length > 0)
  //                   _themeBox('${pointLists[0]['name']}', () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                           builder: (context) =>
  //                               PointDetailsScreen(pointList: pointLists[0])),
  //                     );
  //                   }),
  //                 if (pointLists.length > 1)
  //                   _themeBox('${pointLists[1]['name']}', () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                           builder: (context) =>
  //                               PointDetailsScreen(pointList: pointLists[1])),
  //                     );
  //                   }),
  //               ],
  //             ),
  //           ],
  //         );
  //       } else {
  //         return Center(child: Text('No data'));
  //       }
  //     },
  //   );
  // }
  //
  // Widget _themeBox(String title, VoidCallback onTap) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       width: 190,
  //       height: 220,
  //       decoration: BoxDecoration(
  //         color: Colors.white, // 박스의 배경색
  //         borderRadius: BorderRadius.circular(15), // 모서리 둥글게 만들기
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black26,
  //             blurRadius: 5,
  //             offset: Offset(2, 2),
  //           ),
  //         ],
  //       ),
  //       child: Center(
  //         child: Text(
  //           title,
  //           style: const TextStyle(
  //             fontSize: 16,
  //             color: Colors.black,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _themeBox(String title, VoidCallback onTap) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       width: 190,
  //       height: 220,
  //       decoration: BoxDecoration(
  //         color: Colors.white, // 박스의 배경색
  //         borderRadius: BorderRadius.circular(15), // 모서리 둥글게 만들기
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black26,
  //             blurRadius: 5,
  //             offset: Offset(2, 2),
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Image.asset(
  //             'asset/${title}_theme.png',
  //             width: 100,
  //             height: 100,
  //           ),
  //           SizedBox(height: 10), // 이미지와 텍스트 사이의 간격
  //           Text(
  //             title,
  //             style: const TextStyle(
  //               fontSize: 16,
  //               color: Colors.black,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildThemeBox(double screenWidth, double screenHeight) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getPointsLists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          List<Map<String, dynamic>> pointLists = snapshot.data!;
          return Column(
            children: [
              Text(
                '오늘의 추천 테마',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (pointLists.length > 0)
                    Flexible(
                      child: _themeBox(
                        '${pointLists[0]['name']}',
                        screenWidth,
                        screenHeight,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PointDetailsScreen(pointList: pointLists[0]),
                            ),
                          );
                        },
                      ),
                    ),
                  if (pointLists.length > 1)
                    Flexible(
                      child: _themeBox(
                        '${pointLists[1]['name']}',
                        screenWidth,
                        screenHeight,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PointDetailsScreen(pointList: pointLists[1]),
                            ),
                          );
                        },
                        textAlign: TextAlign.center, // Center align text
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.0), // Add horizontal padding
                      ),
                    ),
                ],
              ),
            ],
          );
        } else {
          return Center(child: Text('No data'));
        }
      },
    );
  }

  Widget _themeBox(
      String title, double screenWidth, double screenHeight, VoidCallback onTap,
      {TextAlign textAlign = TextAlign.left,
      EdgeInsets padding = const EdgeInsets.all(0)}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.45, // 화면 너비의 45%를 사용
        height: screenHeight * 0.30, // 화면 높이의 30%를 사용
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAE9), // 박스의 배경색
          borderRadius: BorderRadius.circular(15), // 모서리 둥글게 만들기
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'asset/places/${title}_theme.png',
              width: 100,
              height: 100,
            ),
            SizedBox(height: 25), // 이미지와 텍스트 사이의 간격
            Text(
              title,
              textAlign: TextAlign.center, // Center align text
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
