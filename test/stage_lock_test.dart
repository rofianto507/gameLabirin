// Unit test untuk aturan urutan stage: harus selesai berurutan, dan dunia
// baru hanya terbuka setelah seluruh dunia sebelumnya tamat.
import 'package:flutter_test/flutter_test.dart';
import 'package:kuna_labirin/data/models.dart';

void main() {
  group('isStageUnlocked', () {
    test('stage 1 dunia pertama selalu terbuka walau belum ada progres', () {
      expect(isStageUnlocked({}, 0, 1), isTrue);
    });

    test('stage berikutnya di dunia yang sama terkunci sampai yang sebelumnya selesai', () {
      expect(isStageUnlocked({}, 0, 2), isFalse);
      expect(isStageUnlocked({'0_1': 0}, 0, 2), isFalse,
          reason: '0 bintang = belum pernah menang, masih terkunci');
      expect(isStageUnlocked({'0_1': 1}, 0, 2), isTrue);
    });

    test('dunia baru terkunci sampai seluruh dunia sebelumnya tamat', () {
      final hampirTamat = {
        for (var s = 1; s < stagesPerWorld; s++) '0_$s': 1,
      }; // stage terakhir dunia 0 belum selesai
      expect(isStageUnlocked(hampirTamat, 1, 1), isFalse);

      final tamat = {
        for (var s = 1; s <= stagesPerWorld; s++) '0_$s': 1,
      };
      expect(isStageUnlocked(tamat, 1, 1), isTrue);
    });

    test('stage pertama dunia kedua tidak terpengaruh progres dunia ketiga dst.', () {
      final tamatDunia0 = {
        for (var s = 1; s <= stagesPerWorld; s++) '0_$s': 1,
      };
      expect(isStageUnlocked(tamatDunia0, 1, 2), isFalse,
          reason: 'stage 2 dunia 1 masih perlu stage 1 dunia 1 selesai dulu');
    });
  });
}
