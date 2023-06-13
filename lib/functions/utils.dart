String getWeekday(int weekdayNumber) {
  switch (weekdayNumber) {
    case 2:
      return 'Segunda';
    case 3:
      return 'Terça';
    case 4:
      return 'Quarta';
    case 5:
      return 'Quinta';
    case 6:
      return 'Sexta';
    case 7:
      return 'Sábado';
    case 8:
      return 'Domingo';
    default:
      return '';
  }
}

String getFormattedTime(int time) {
  return '${(time ~/ 100).toString().padLeft(2, '0')}:${(time % 100).toString().padLeft(2, '0')}';
}
