enum ZoneLocationType { ANVIL, INN, SHOP, FISHING }

class ZoneLocation {
  final String name;
  final ZoneLocationType type;

  _getIconAssetForType(ZoneLocationType type) {
    switch (type) {
      case ZoneLocationType.ANVIL:
        return 'assets/icons/anvil.png';
      case ZoneLocationType.INN:
        return 'assets/icons/inn.png';
      case ZoneLocationType.SHOP:
        return 'assets/icons/shop.png';
      case ZoneLocationType.FISHING:
        return 'assets/icons/fishing.png';
    }
  }

  ZoneLocation({required this.name, required this.type});

  factory ZoneLocation.fromJson(Map<String, dynamic> json) {
    return ZoneLocation(
      name: json['name'] as String,
      type: ZoneLocationType.values.firstWhere(
        (e) => e.toString() == 'ZoneLocationType.${json['type']}',
        orElse: () =>
            throw ArgumentError('Invalid ZoneLocationType: ${json['type']}'),
      ),
    );
  }
}

class ZoneLocationController {
  static final List<ZoneLocation> locations = [
    ZoneLocation(name: 'Anvil', type: ZoneLocationType.ANVIL),
    ZoneLocation(name: 'Inn', type: ZoneLocationType.INN),
    ZoneLocation(name: 'Shop', type: ZoneLocationType.SHOP),
    ZoneLocation(name: 'Fishing Spot', type: ZoneLocationType.FISHING),
  ];
}
