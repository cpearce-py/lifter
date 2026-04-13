
const fullDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const fullMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> ranges = ['1W', '1M', '3M', '6M', 'YTD', '1Y'];

double displayWeight(double weightInKg, bool useLbs) {
  return useLbs ? weightInKg * 2.20462 : weightInKg;
}

String weightUnit(bool useLbs) => useLbs ? 'lbs' : 'kg';

