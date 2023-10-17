import 'package:flutter/material.dart';

// ----- Colors -----
const black =         Color(0xFF2C2C2C);
const white =         Color(0xFFFFFFFF);

// ----- Fonts -----
h1([color]) => TextStyle(
  fontFamily: 'NotoSansJP',
  fontSize: 24,
  fontWeight: FontWeight.w700,
  color: color ?? black,
  height: 1.5,
);