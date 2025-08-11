// lib/repository/ble_camera_repository.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:eye_set_mobile/protos/meshtastic/mesh.pb.dart' as mesh;
import 'package:eye_set_mobile/protos/meshtastic/portnums.pbenum.dart'
    as portnum;
import 'package:eye_set_mobile/repository/mock_camera_repository.dart';

import '../model/camera.dart';
import 'camera_repository.dart';

/// Stub for a BLE‑backed repository.
/// Replace the TODOs with calls to your BLE plugin.
class BleCameraRepository implements CameraRepository {
  // Meshtastic MeshBluetoothService + characteristics
  static final UUID meshServiceUuid = UUID.fromString(
    '6ba1b218-15a8-461f-9fa8-5dcae273eafd',
  ); // service

  static final UUID toRadioUuid = UUID.fromString(
    'f75c76d2-129e-4dad-a1dd-7866124401e7',
  ); // write
  static final UUID fromRadioUuid = UUID.fromString(
    '2c55e69e-4993-11ed-b878-0242ac120002',
  ); // read
  static final UUID fromNumUuid = UUID.fromString(
    'ed9da18c-a800-4f66-a670-aa7547e34453',
  ); // read/notify/write
  static final UUID logRecordUuid = UUID.fromString(
    '5a3d6e49-06e6-4423-9944-e9de8cdf9547',
  ); // notify (optional)

  final PeripheralManager _pm = PeripheralManager();

  // ------------------------------------------------------------------
  //  STATE
  // ------------------------------------------------------------------
  final _cameras = <Camera>[];
  final _controller = StreamController<List<Camera>>.broadcast();

  BleCameraRepository() {
    // When the BLE service starts, you could scan for devices,
    // connect, and populate `_cameras`. For demo purposes we
    // start with an empty list.
    _controller.add(_cameras);
  }

  GATTService? _meshService;
  bool _isAdvertising = false;
  StreamSubscription? _onReadSub;
  StreamSubscription? _onWriteSub;

  Future<void> _ensurePoweredOn() async {
    if (_pm.state != BluetoothLowEnergyState.poweredOn) {
      await _pm.stateChanged.firstWhere(
        (e) => e.state == BluetoothLowEnergyState.poweredOn,
      );
    }
  }

  void _handleToRadioWrite(Uint8List value) {
    try {
      final msg = mesh.ToRadio.fromBuffer(value);
      if (msg.hasPacket() && msg.packet.hasDecoded()) {
        final decoded = msg.packet.decoded;
        if (decoded.portnum == portnum.PortNum.NODEINFO_APP) {
          final nodeInfo = mesh.NodeInfo.fromBuffer(decoded.payload);
          // For now we simply log the node name and model.
          print('Connected node: ${nodeInfo.user.longName} ');
        }
      }
    } catch (_) {
      // Ignore parse errors for now; this will be expanded later.
    }
  }

  /// Call when Camera List opens.
  @override
  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    // Ask for permissions (Android 12+: advertise/connect/scan).
    if (Platform.isAndroid) {
      try {
        await _pm.authorize();
      } on UnsupportedError {
        // Authorization is not supported on this platform; continue.
      }
    }

    await _ensurePoweredOn();

    // Build the service (Meshtastic layout)
    final toRadio = GATTCharacteristic.mutable(
      uuid: toRadioUuid,
      properties: const [GATTCharacteristicProperty.write],
      permissions: const [GATTCharacteristicPermission.write],
      descriptors: const [],
    );

    final fromRadio = GATTCharacteristic.mutable(
      uuid: fromRadioUuid,
      properties: const [GATTCharacteristicProperty.read],
      permissions: const [GATTCharacteristicPermission.read],
      descriptors: const [],
    );

    final fromNum = GATTCharacteristic.mutable(
      uuid: fromNumUuid,
      properties: const [
        GATTCharacteristicProperty.read,
        GATTCharacteristicProperty.notify,
        GATTCharacteristicProperty.write,
      ],
      permissions: const [
        GATTCharacteristicPermission.read,
        GATTCharacteristicPermission.write,
      ],
      descriptors: const [],
    );

    final logRecord = GATTCharacteristic.mutable(
      uuid: logRecordUuid,
      properties: const [GATTCharacteristicProperty.notify],
      permissions: const [],
      descriptors: const [],
    );

    _meshService = GATTService(
      uuid: meshServiceUuid,
      isPrimary: true,
      includedServices: const [],
      characteristics: [fromRadio, toRadio, fromNum, logRecord],
    );

    // Publish the service
    await _pm.removeAllServices();
    await _pm.addService(_meshService!);

    // Hook minimal handlers (you can expand these later)
    _onReadSub = _pm.characteristicReadRequested.listen((evt) async {
      // Example: reply with an empty buffer for FromRadio when polled.
      if (evt.characteristic.uuid == fromRadioUuid) {
        await _pm.respondReadRequestWithValue(evt.request, value: Uint8List(0));
      } else if (evt.characteristic.uuid == fromNumUuid) {
        await _pm.respondReadRequestWithValue(
          evt.request,
          value: Uint8List.fromList([0]),
        );
      } else {
        await _pm.respondReadRequestWithError(
          evt.request,
          error: GATTError.requestNotSupported,
        );
      }
    });

    _onWriteSub = _pm.characteristicWriteRequested.listen((evt) async {
      if (evt.characteristic.uuid == toRadioUuid) {
        final value = evt.request.value;
        _handleToRadioWrite(value);
      }
      // Accept writes to ToRadio / FromNum without processing yet.
      await _pm.respondWriteRequest(evt.request);
    });

    // Start advertising (name + service UUID only per platform limits)
    await _pm.startAdvertising(
      Advertisement(name: "EyeSet", serviceUUIDs: [meshServiceUuid]),
    );

    _isAdvertising = true;
  }

  /// Call when Camera List closes (or on dispose).
  @override
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    await _pm.stopAdvertising();
    _isAdvertising = false;

    await _onReadSub?.cancel();
    await _onWriteSub?.cancel();
    _onReadSub = null;
    _onWriteSub = null;

    await _pm.removeAllServices();
    _meshService = null;
  }

  bool get isAdvertising => _isAdvertising;

  // ------------------------------------------------------------------
  //  PUBLIC API
  // ------------------------------------------------------------------
  @override
  Stream<List<Camera>> get cameras => _controller.stream;

  @override
  Future<void> addCamera(Camera camera) async {
    // TODO: send a BLE write that creates a new camera.
    // On success, update the local list.
    _cameras.add(camera);
    _controller.add(List.of(_cameras));
  }

  @override
  Future<void> removeCamera(int index) async {
    if (index < 0 || index >= _cameras.length) return;
    // TODO: send a BLE write to delete the camera.
    _cameras.removeAt(index);
    _controller.add(List.of(_cameras));
  }

  @override
  Future<File> getCameraPreview(Camera camera) async {
    // TODO: request the preview image over BLE (most likely as a byte array).
    // Here we simply delegate to the mock implementation so the UI
    // continues to work while you fill in the BLE code.
    final mock = MockCameraRepository();
    return await mock.getCameraPreview(camera);
  }
}
