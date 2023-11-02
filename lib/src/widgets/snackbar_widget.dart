import 'package:flutter/material.dart';

showSnackbar(context,text){
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 1),
    )
  );
}