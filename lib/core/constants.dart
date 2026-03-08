class AppConstants {
  // ==================== 血糖单位 ====================
  static const String unitMgDl = 'mg/dL';
  static const String unitMmolL = 'mmol/L';
  
  // 血糖转换公式
  static double mgdlToMmoll(double mgdl) => mgdl / 18.0182;
  static double mmollToMgdl(double mmol) => mmol * 18.0182;
  // 兼容旧代码
  static double mmolLToMgDl(double value) => mmollToMgdl(value);
  static double mgDlToMmolL(double value) => mgdlToMmoll(value);
  
  // HbA1c 计算 (mg/dL)
  static double calculateHbA1c(double avgBloodSugar) {
    return (46.7 + avgBloodSugar) / 28.7;
  }
  
  // 根据 HbA1c 计算平均血糖
  static double calculateAvgBloodSugar(double hba1c) {
    return hba1c * 28.7 - 46.7;
  }
  
  // 血糖安全范围 (mg/dL)
  static const double defaultSafeMin = 70.0;
  static const double defaultSafeMax = 140.0;
  
  // 血糖安全范围 (mmol/L)
  static const double defaultSafeMinMmol = 3.9;
  static const double defaultSafeMaxMmol = 7.8;
  
  // 餐后小时选项
  static const List<double> postMealHours = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
  
  // ==================== 运动类型 ====================
  // 有氧运动类型 - 户外
  static const List<String> outdoorAerobicExercises = [
    '跑步',
    '步行',
    '骑行',
    '登山',
  ];
  
  // 有氧运动类型 - 室内
  static const List<String> indoorAerobicExercises = [
    '椭圆机',
    '室内单车',
  ];
  
  // 所有有氧运动类型
  static const List<String> aerobicExercises = [
    '跑步',
    '步行',
    '骑行',
    '登山',
    '椭圆机',
    '室内单车',
    '游泳',
    '跳绳',
    '划船机',
    '其他',
  ];
  
  // 力量训练器械
  static const List<String> strengthDevices = [
    '哑铃',
    '杠铃',
    '史密斯机',
    '龙门架',
    '腿举机',
    '高位下拉器',
    '划船机',
    '其他',
  ];
  
  // 耐力训练类型
  static const List<String> enduranceTypes = [
    '波比跳',
    '平板支撑',
    '登山跑',
    '深蹲跳',
    '开合跳',
    '高抬腿',
    '其他',
  ];
  
  // 需要距离记录的运动类型
  static const List<String> distanceExercises = [
    '跑步',
    '骑行',
    '登山',
  ];
  
  // 需要功率记录的运动类型
  static const List<String> powerExercises = [
    '椭圆机',
    '室内单车',
  ];
}
