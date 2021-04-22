import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:convert';
import '../elements/custom.dart' as custom;
import '../elements/config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import '../page/add_product.dart' as add;

class Product extends StatefulWidget {
  @override
  _ProductState createState() => _ProductState();
}

class _ProductState extends State<Product> {
  bool isLoading = true;
  bool haveItem = false;
  int productCount;
  final searchController = TextEditingController();
  List<dynamic> product;

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      if(barcodeScanRes != "-1") {
        final response = await http.get(Uri.parse("https://microservice.mitrainformatika.net/barcode/general/$barcodeScanRes"));
        Map<String, dynamic> json = jsonDecode(response.body);
        if(json["item_count"] != 0) {
            Navigator.push(
              context,
                PageTransition(
                child: add.AddProduct(productsId: barcodeScanRes, name: json["item_data"][0]["name"]),
                type: PageTransitionType.rightToLeft,
                inheritTheme: true,
                ctx: context
            ) 
          );
        } else {
          AlertDialog noItems = AlertDialog(
            title: Text("Sorry"),
            content: Text("Items not found in our database."),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return noItems;
            },
          );
        }
      }
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;
  }

  void getProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('loginToken');
    String key = "Bearer $token";
    List<dynamic> json;    

    final response = await http.get(
      Uri.parse("$url/api/auth/products"),
      headers: <String, String> {
        'Accept': 'application/json',
        'Authorization': key,
      },
    );

    if(this.mounted) {
      try {
        setState(() {
          Map<String, dynamic> data = jsonDecode(response.body);
          json = data["data"];
          if(json.length > 0) {
            haveItem = true;
            isLoading = false;
            productCount = json.length;
            product = json;
          } else {
            isLoading = false;
          }
        });
      } on PlatformException {
        print("Something was wrong");
      }
    }
  }

  void initState() {
    super.initState();
    getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 3,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Colors.black
        ),
        title: Text("Products", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold))
      ),
      body: haveItem ?
      Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 78,
                    child: custom.CustomTextField(controller: searchController, hintText: "Search", obscureText: false)
                  ),
                  IconButton(icon: Icon(Icons.search), onPressed: scanBarcodeNormal, color: Colors.blue)
                ],
              ),
            ),
            SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height - 170,
                padding: EdgeInsets.only(left: 10, right:10, bottom: 10),
                child: ListView.builder(
                  itemCount: productCount,
                  itemBuilder: (context, index) {
                    return custom.ListProduct(
                      img: "https://bwipjs-api.metafloor.com/?bcid=code128&text=${product[index]["products_id"]}",
                      name: product[index]["name"],
                      price: product[index]["price"].toString(),
                      buttonPressed: scanBarcodeNormal,
                    );
                  }
                )
              ),
            ),
          ],
        ),
      ) : 
      Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [ 
            isLoading ?
            LinearProgressIndicator(minHeight: 1, backgroundColor: Colors.blue)
            : SizedBox(height: 0),
            SizedBox(height: MediaQuery.of(context).size.height*0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("images/box.png", width: 100),
                  SizedBox(height: 20),
                  Text("No product yet.", style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text("Scan product's barcode to add your product to inventory", style: TextStyle(color: Colors.black, fontSize: 15), textAlign: TextAlign.center)
                  ),
                ],
              ),
            )
          ]
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: scanBarcodeNormal,
        child: Icon(Icons.qr_code_scanner_outlined, color: Colors.white)
      ),
    );
  }
}