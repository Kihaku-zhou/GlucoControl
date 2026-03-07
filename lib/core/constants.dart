class AppConstants {
  // App 信息
  static const String appName = 'GlucoControl';
  static const String appVersion = '0.1.0';
  
  // 血糖单位
  static const String unitMgDl = 'mg/dL';
  static const String unitMmolL = 'mmol/L';
  
  // 血糖类型
  static const String bloodSugarFasting = 'fasting';
  static const String bloodSugarPostMeal = 'post_meal';
  static const String bloodSugarCustom = 'custom';
  
  // 餐后时间选项（小时）
  static const List<double> postMealHours = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
  
  // 运动类型
  static const String exerciseAerobic = 'aerobic';
  static const String exerciseAnaerobic = 'anaerobic';
  
  // 餐次
  static const String mealBreakfast = 'breakfast';
  static const String mealLunch = 'lunch';
  static const String mealDinner = 'dinner';
  static const String mealSnack = 'snack';
  
  // 器械类型
  static const List<String> strengthDevices = [
    '哑铃',
    '杠铃',
    '壶铃',
    '器械',
    '自重',
    '弹力带',
    '其他',
  ];
  
  // 有氧运动类型
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
  
  // WebDAV 默认坚果云地址
  static const String defaultWebDavUrl = 'https://dav.jianguoyun.com/dav/';
  
  // HbA1c 计算公式常数
  static const double hba1cConstant1 = 46.7;
  static const double hba1cConstant2 = 28.7;
  
  /// mg/dL 转 mmol/L
  static double mgDlToMmolL(double mgDl) {
    return mgDl / 18.0182;
  }
  
  /// mmol/L 转 mg/dL
  static double mmolLToMgDl(double mmolL) {
    return mmolL * 18.0182;
  }
  
  /// 根据平均血糖计算 HbA1c
  /// 公式: ((平均血糖 + 46.7) / 28.7)
  static double calculateHbA1c(double avgBloodSugar) {
    return (avgBloodSugar + hba1cConstant1) / hba1cConstant2;
  }
  
  /// 根据 HbA1c 计算平均血糖
  /// 公式: (HbA1c * 28.7) - 46.7
  static double calculateAvgBloodSugar(double hba1c) {
    return (hba1c * hba1cConstant2) - hba1cConstant1;
  }
}
