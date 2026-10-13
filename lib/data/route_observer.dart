import 'package:flutter/material.dart';

/// Observer global untuk mendeteksi kapan sebuah layar menjadi terlihat lagi,
/// baik lewat push baru maupun kembali dari pop (lihat [RouteAware]).
/// Dipakai untuk mengulang musik latar dari awal setiap pindah halaman.
final RouteObserver<PageRoute<void>> routeObserver =
    RouteObserver<PageRoute<void>>();
