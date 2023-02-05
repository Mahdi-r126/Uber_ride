import 'package:flutter/material.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:uber/Styles/styles.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          Container(
            color: Colors.white,
            height: 160,
            child: DrawerHeader(
              child: Row(
                children: [
                  Image.asset("assets/images/user_icon.png",
                      height: 60, width: 60),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Mahdi",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "View Profile",
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          const Divider(color: Colors.black54),
          const SizedBox(
            height: 10,
          ),
          ListTile(
            leading: const Icon(OMIcons.cardGiftcard),
            title: Text("Free Rides", style: DrawerItemStyles),
          ),
          ListTile(
            leading: const Icon(OMIcons.payment),
            title: Text("Payment", style: DrawerItemStyles),
          ),
          ListTile(
            leading: const Icon(OMIcons.history),
            title: Text("Ride History", style: DrawerItemStyles),
          ),
          ListTile(
            leading: const Icon(OMIcons.contactSupport),
            title: Text("Support", style: DrawerItemStyles),
          ),
          ListTile(
            leading: const Icon(OMIcons.info),
            title: Text("About", style: DrawerItemStyles),
          ),
        ],
      ),
    );
  }
}
