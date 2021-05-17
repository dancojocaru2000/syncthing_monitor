enum DataUnit {
  b,
  kb,
  mb,
  gb,
  tb
}

extension DataUnitToString on DataUnit {
  String toBinaryString() {
    switch (this) {
      case DataUnit.b:
        return "";
      case DataUnit.kb:
        return "Ki";
      case DataUnit.mb:
        return "Mi";
      case DataUnit.gb:
        return "Gi";
      case DataUnit.tb:
        return "Ti";
      default:
        throw Exception("Unknown data unit");
    }
  }
}

class DataUnitConversionResult {
  final double value;
  final DataUnit unit;

  DataUnitConversionResult(this.value, this.unit);
}

extension BytesToDataUnitConversion on double {
  DataUnitConversionResult toDataUnit({double minimumValue = 0.9}) {
    var unit = -1;
    var value = this;
    var next = value;

    do {
      value = next;
      unit++;
      next = value / 1024;
    } while(unit != DataUnit.values.length - 1 && next > minimumValue);

    return DataUnitConversionResult(value, DataUnit.values[unit]);
  }
}