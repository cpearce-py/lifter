const double _kgToLbsRatio = 2.20462;

double kgToLbs(double kg) {
return double.parse((kg * _kgToLbsRatio).toStringAsFixed(1));
}

double lbsToKg(double lbs) {
return double.parse((lbs / _kgToLbsRatio).toStringAsFixed(1));
}
