// ==========================================
// BORSA SİNYAL FLUTTER - SIGNAL MODEL
// ==========================================
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'signal.freezed.dart';
part 'signal.g.dart';

@freezed
@Collection()
class Signal with _$Signal {
  const factory Signal({
    @Default('') @Id() String id,
    required DateTime date,
    required String direction, // 'UP', 'DOWN', 'FLAT'
    required double confidence,
    @Default({}) Map<String, dynamic> components,
    required String modelVersion,
    required DateTime createdAt,
  }) = _Signal;

  factory Signal.fromJson(Map<String, dynamic> json) => _$SignalFromJson(json);
  
  const Signal._();
  
  // Helper getters
  bool get isUp => direction == 'UP';
  bool get isDown => direction == 'DOWN';
  bool get isFlat => direction == 'FLAT';
  
  Color get directionColor {
    switch (direction) {
      case 'UP': return const Color(0xFF2E7D32);
      case 'DOWN': return const Color(0xFFD32F2F);
      default: return const Color(0xFFED6C02);
    }
  }
  
  String get directionLabel {
    switch (direction) {
      case 'UP': return 'YÜKSELİŞ BEKLENİYOR';
      case 'DOWN': return 'DÜŞÜŞ BEKLENİYOR';
      default: return 'YATAY SEYİR BEKLENİYOR';
    }
  }
  
  IconData get directionIcon {
    switch (direction) {
      case 'UP': return Icons.trending_up_rounded;
      case 'DOWN': return Icons.trending_down_rounded;
      default: return Icons.trending_flat_rounded;
    }
  }
}