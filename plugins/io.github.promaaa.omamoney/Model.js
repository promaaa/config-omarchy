// Model.js - Helper functions and multi-currency formatting for OmaMoney

var CURRENCY_SYMBOLS = {
  "EUR": "€",
  "KRW": "₩",
  "USD": "$",
  "JPY": "¥",
  "GBP": "£",
  "CHF": "Fr",
  "CAD": "CA$",
  "AUD": "AU$",
  "CNY": "¥",
  "SGD": "SG$",
  "THB": "฿",
  "VND": "₫",
  "INR": "₹",
  "BRL": "R$",
  "TWD": "NT$",
  "MXN": "Mex$",
  "NZD": "NZ$",
  "HKD": "HK$",
  "SEK": "kr",
  "NOK": "kr",
  "DKK": "kr",
  "PLN": "zł",
  "TRY": "₺",
  "ZAR": "R",
  "AED": "AED",
  "SAR": "SAR",
  "PHP": "₱",
  "IDR": "Rp",
  "MYR": "RM"
}

function getSymbol(code) {
  return CURRENCY_SYMBOLS[code] || code
}

function formatNumber(num, decimals) {
  if (isNaN(num) || num === null || num === undefined) return "0"
  var d = (decimals !== undefined) ? decimals : 2
  var parts = Number(num).toFixed(d).split(".")
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  return parts.join(".")
}

function formatCurrencyAmount(num, currencyCode) {
  if (isNaN(num) || num === null || num === undefined) return "0"
  var code = (currencyCode || "").toUpperCase()
  // Currencies without decimals (zero-decimal currencies)
  if (code === "KRW" || code === "JPY" || code === "VND" || code === "IDR" || code === "CLP" || code === "HUF") {
    var val = Math.round(Number(num))
    return val.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  }
  return formatNumber(num, 2)
}

function formatKoreanUnits(amount) {
  var abs = Math.abs(Number(amount))
  if (abs >= 100000000) {
    var eok = amount / 100000000
    return formatNumber(eok, 2) + " eok won"
  } else if (abs >= 10000) {
    var man = amount / 10000
    return formatNumber(man, 1) + " man won"
  } else {
    return formatCurrencyAmount(amount, "KRW") + " won"
  }
}

function getRate(fromCode, toCode, rates) {
  if (!rates) return 1.0
  var fromRate = rates[fromCode] !== undefined ? Number(rates[fromCode]) : 1.0
  var toRate = rates[toCode] !== undefined ? Number(rates[toCode]) : 1.0
  if (fromRate === 0) return 1.0
  return toRate / fromRate
}

function parseConfig(raw) {
  var defaultConfig = {
    baseCurrency: "EUR",
    targetCurrency: "KRW",
    barStyle: "standard",
    minimized: false,
    barMode: 0,
    presets: [
      { icon: "󰅶", name: "Coffee / Americano", amount: 3500, isBase: false },
      { icon: "󰛲", name: "SNU 301 Cafeteria", amount: 6500, isBase: false },
      { icon: "󰄲", name: "Subway (T-Money)", amount: 1500, isBase: false },
      { icon: "󰋜", name: "Studio / Dorm Rent", amount: 600000, isBase: false },
      { icon: "󰉋", name: "Monthly Budget", amount: 1000, isBase: true }
    ],
    majorCurrencies: ["USD", "JPY", "GBP", "CHF", "CAD", "AUD"]
  }

  if (!raw || !raw.trim()) return defaultConfig

  try {
    var data = JSON.parse(raw)
    var isMin = (data.minimized === true) || (data.barStyle === "icon") || (data.barMode === 4)
    return {
      baseCurrency: (data.baseCurrency || "EUR").toUpperCase(),
      targetCurrency: (data.targetCurrency || "KRW").toUpperCase(),
      barStyle: data.barStyle || (isMin ? "icon" : "standard"),
      minimized: isMin,
      barMode: typeof data.barMode === "number" ? data.barMode : (isMin ? 4 : 0),
      presets: Array.isArray(data.presets) && data.presets.length > 0 ? data.presets : defaultConfig.presets,
      majorCurrencies: Array.isArray(data.majorCurrencies) && data.majorCurrencies.length > 0 ? data.majorCurrencies : defaultConfig.majorCurrencies
    }
  } catch (e) {
    return defaultConfig
  }
}
