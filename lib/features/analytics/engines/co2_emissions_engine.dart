/// Result of a CO2 emissions calculation.
class Co2Result {
  final double petrolKg;
  final double dieselKg;
  final double totalKg;
  final double totalTonnes;

  /// Mature trees needed to absorb a year of these emissions.
  final int equivalentTreesYearly;

  /// Equivalent number of one-way Colombo→London passenger flights.
  final int equivalentFlights;

  const Co2Result({
    required this.petrolKg,
    required this.dieselKg,
    required this.totalKg,
    required this.totalTonnes,
    required this.equivalentTreesYearly,
    required this.equivalentFlights,
  });

  static const Co2Result zero = Co2Result(
    petrolKg: 0,
    dieselKg: 0,
    totalKg: 0,
    totalTonnes: 0,
    equivalentTreesYearly: 0,
    equivalentFlights: 0,
  );
}

/// Pure rule-based CO2 calculator using EPA / IPCC well-to-wheel factors.
/// Inputs are litres of fuel; output is fully derived. Works on any data
/// source — mock today, Firestore later, no code changes needed.
class Co2EmissionsEngine {
  /// kg CO2 per litre of petrol (EPA: 8.887 kg per gallon ≈ 2.31 per litre).
  static const double petrolFactorKgPerLitre = 2.31;

  /// kg CO2 per litre of diesel (EPA: 10.180 kg per gallon ≈ 2.68 per litre).
  static const double dieselFactorKgPerLitre = 2.68;

  /// One mature tree absorbs ~21 kg CO2 per year (US Forest Service).
  static const double treeAbsorptionKgPerYear = 21;

  /// Per-passenger CO2 for one Colombo → London economy flight (~1.6 t).
  static const double flightTonnesPerPassenger = 1.6;

  /// Compute emissions for a given period (the litres you pass in define the
  /// period — monthly litres ⇒ monthly result, weekly ⇒ weekly, etc.).
  static Co2Result compute({
    required double petrolLitres,
    required double dieselLitres,
  }) {
    if (petrolLitres < 0 || dieselLitres < 0) return Co2Result.zero;

    final petrolKg = petrolLitres * petrolFactorKgPerLitre;
    final dieselKg = dieselLitres * dieselFactorKgPerLitre;
    final totalKg = petrolKg + dieselKg;
    final totalTonnes = totalKg / 1000;

    // Project to a year for tree-equivalent (assuming the input was monthly).
    final yearlyKg = totalKg * 12;
    final trees = (yearlyKg / treeAbsorptionKgPerYear).round();
    final flights = (totalTonnes / flightTonnesPerPassenger).round();

    return Co2Result(
      petrolKg: petrolKg,
      dieselKg: dieselKg,
      totalKg: totalKg,
      totalTonnes: totalTonnes,
      equivalentTreesYearly: trees,
      equivalentFlights: flights,
    );
  }
}
