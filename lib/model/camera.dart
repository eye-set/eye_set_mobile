enum CameraStatus { offline, bluetooth, wifi }

class Camera {
  final String id;
  final String name;
  final String model;
  final CameraStatus status;

  Camera({
    required this.id,
    required this.name,
    required this.model,
    this.status = CameraStatus.offline,
  });

  Camera copyWith({
    String? id,
    String? name,
    String? model,
    CameraStatus? status,
  }) {
    return Camera(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      status: status ?? this.status,
    );
  }
}
