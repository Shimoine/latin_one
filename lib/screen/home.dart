import 'package:flutter/material.dart';
import './product.dart';
import './topic2.dart';
import '../page.dart';
import '../style.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: ListView(
            children: <Widget>[
              // Order section
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    width: 350,
                    height: 200,
                    decoration: background_image('assets/images/coffee.jpg'),
                    alignment: Alignment.center,
                      child: const Text(
                          'MOBILE ORDER & PAY',
                          style: Default_title_Style
                      )
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: ElevatedButton(
                      onPressed: () {
                        var mainPageState = context.findAncestorStateOfType<Pages>();
                        mainPageState?.onItemTapped(2);
                      },
                      child: const Text('Order をする',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Menu section
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    width: 350,
                    height: 200,
                    decoration: background_image('assets/images/IMG_8836.jpg'),
                    alignment: Alignment.center,
                      child: const Text(
                          'COFFEE LIST',
                          style: Default_title_Style
                      )
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductPage(isFromHomePage: true),
                          ),
                        );
                      },
                      child: const Text('Menu を見る',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Topic2 section
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    width: 350,
                    height: 200,
                    decoration: background_image('assets/images/IMG_8837.jpg'),
                    alignment: Alignment.center,
                      child: const Text(
                          'topic2',
                          style: Default_title_Style
                      )
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Topic2Page(),
                          ),
                        );
                      },
                      child: const Text('Topic2',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
