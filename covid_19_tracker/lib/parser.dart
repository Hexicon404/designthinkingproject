import 'package:covid_19_tracker/chartsdata.dart';
import 'package:covid_19_tracker/countrydata.dart';

class Parser {
  static CountryData parseRow(List<String> row, bool hasInnerTag, String link) {
    int offset = hasInnerTag ? 0 : -2;
    CountryData cD = new CountryData();
    cD.totalCases = parseInteger(row[7 + offset]);
    cD.newCases = parseInteger(row[9 + offset]);
    cD.totalDeaths = parseInteger(row[11 + offset]);
    cD.newDeaths = parseInteger(row[13 + offset]);
    cD.totalRecovered = parseInteger(row[15 + offset]);
    cD.activeCases = parseInteger(row[19 + offset]);
    cD.criticalCases = parseInteger(row[21 + offset]);
    cD.casesPerMln = parseDouble(row[23 + offset]);
    cD.deathsPerMln = parseDouble(row[25 + offset]);
    cD.totalTests = parseInteger(row[27 + offset]);
    cD.testsPerMln = parseInteger(row[29 + offset]);
    cD.link = link;
    return cD;
  }

  static int parseInteger(String s) {
    try {
      return int.parse(s.split("<")[0].replaceAll(",", "").replaceAll("+", ""));
    } catch (e) {
      return 0;
    }
  }

  static double parseDouble(String s) {
    try {
      return double.parse(s.split("<")[0].replaceAll(",", "").replaceAll("+", ""));
    } catch (e) {
      return 0;
    }
  }

  static String getInnerString(String source, String a, String b) {
    return source.split(a)[1].split(b)[0];
  }

  static String normalizeName(String n) {
    return n.replaceAll("&ccedil;", "ç").replaceAll("&eacute;", "é").split("<")[0];
  }

  static Map<String, CountryData> getCountryData(String body) {
    Map<String, CountryData> countryData = {};
    var row = body.split("<tr class=\"total_row\">")[1].split("</tr>")[0].split(">");

    countryData["Global"] = parseRow(row, true, "");

    var tbody = getInnerString(body, "<tbody>", "</tbody>");
    var rows = tbody.split("<tr style=\"\">");
    rows.skip(1).forEach((rawRow) {
      row = rawRow.split(">");
      bool hasInnerTag = rawRow.contains("</a>") || rawRow.contains("</span>");
      countryData[normalizeName(row[hasInnerTag ? 4: 3])] =
          parseRow(row, hasInnerTag, rawRow.contains("</a>") ? getInnerString(rawRow, "href=\"", "\"") : null);
    });
    return countryData;
  }

  static List<String> getCategories(String s) {
    return s.split("categories: [")[1].split("]")[0].replaceAll("\"", "").split(",");
  }

  static List<int> getDataPoints(String s) {
    return s.split("data: [")[1].split("]")[0].split(",").map(int.parse).toList();
  }

  static ChartsData getChartsData(String body, bool defaultDailyView) {
    var textToParse = body.split("text: 'Total Cases'")[1];
    var xLabels = getCategories(textToParse);
    var values = getDataPoints(textToParse);

    var xLabels2, values2;
    var recoveredDataAvailable = false;
    try {
      textToParse = body.split("text: '(Number of Infected People)")[1];
      xLabels2 = getCategories(textToParse);
      values2 = getDataPoints(textToParse);
      recoveredDataAvailable = true;
    } on RangeError {
      xLabels2 = ["0", "1"];
      values2 = [0, 1];
    }

    textToParse = body.split("text: 'Total Deaths'")[1];
    var xLabels3 = getCategories(textToParse);
    var values3 = getDataPoints(textToParse);

    if(recoveredDataAvailable)
      values2.asMap().forEach((index, value) {
        values2[index] = values[index] - values3[index] - value;
      });

    ChartsData cD = new ChartsData();
    cD.total = new ChartData(xLabels, values, gradientColorsTotal, daily: defaultDailyView);
    cD.recovered = new ChartData(xLabels2, values2, gradientColorsRecovered, daily: defaultDailyView, available: recoveredDataAvailable);
    cD.deaths = new ChartData(xLabels3, values3, gradientColorsDeaths, daily: defaultDailyView);

    return cD;
  }
}
