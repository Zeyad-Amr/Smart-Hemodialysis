class Readings {
  int dialysateLvl;
  int dialysateTemp;
  int bloodFlow;
  int dialysateFlow;
  int drainLvl;
  int status;
  Readings({
    required this.dialysateLvl,
    required this.dialysateTemp,
    required this.bloodFlow,
    required this.dialysateFlow,
    required this.drainLvl,
    required this.status,
  });

  @override
  String toString() {
    return 'Readings(dialysateLvl: $dialysateLvl, dialysateTemp: $dialysateTemp, bloodFlow: $bloodFlow, dialysateFlow: $dialysateFlow, drainLvl: $drainLvl, status: $status)';
  }
}

///
/// Blood Flow
/// Dialysate Flow
/// Dialysate Level 
/// Drain Level 
/// Dialysate Temp
/// Status