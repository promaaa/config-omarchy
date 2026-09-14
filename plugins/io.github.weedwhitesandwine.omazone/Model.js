.pragma library

var CITY_ICONS = {
  // Mexico
  "America/Mexico_City": "🇲🇽",
  "America/Cancun": "🇲🇽",
  "America/Tijuana": "🇲🇽",
  "America/Monterrey": "🇲🇽",
  "America/Hermosillo": "🇲🇽",
  "America/Mazatlan": "🇲🇽",
  "America/Chihuahua": "🇲🇽",
  "America/Merida": "🇲🇽",
  "America/Matamoros": "🇲🇽",
  "America/Bahia_Banderas": "🇲🇽",
  "America/Ciudad_Juarez": "🇲🇽",
  "America/Ojinaga": "🇲🇽",
  "Mexico/BajaNorte": "🇲🇽",
  "Mexico/BajaSur": "🇲🇽",
  "Mexico/General": "🇲🇽",

  // Asia & Pacific
  "Asia/Seoul": "🇰🇷",
  "Asia/Tokyo": "🇯🇵",
  "Asia/Shanghai": "🇨🇳",
  "Asia/Hong_Kong": "🇭🇰",
  "Asia/Taipei": "🇹🇼",
  "Asia/Singapore": "🇸🇬",
  "Asia/Bangkok": "🇹🇭",
  "Asia/Jakarta": "🇮🇩",
  "Asia/Dubai": "🇦🇪",
  "Asia/Kolkata": "🇮🇳",
  "Asia/Calcutta": "🇮🇳",
  "Asia/Jerusalem": "🇮🇱",
  "Asia/Riyadh": "🇸🇦",
  "Australia/Sydney": "🇦🇺",
  "Pacific/Auckland": "🇳🇿",
  "Pacific/Honolulu": "🌺",

  // Europe
  "Europe/Paris": "🇫🇷",
  "Europe/London": "🇬🇧",
  "Europe/Berlin": "🇩🇪",
  "Europe/Rome": "🇮🇹",
  "Europe/Madrid": "🇪🇸",
  "Europe/Amsterdam": "🇳🇱",
  "Europe/Brussels": "🇧🇪",
  "Europe/Zurich": "🇨🇭",
  "Europe/Vienna": "🇦🇹",
  "Europe/Dublin": "🇮🇪",
  "Europe/Lisbon": "🇵🇹",
  "Europe/Stockholm": "🇸🇪",
  "Europe/Oslo": "🇳🇴",
  "Europe/Copenhagen": "🇩🇰",
  "Europe/Warsaw": "🇵🇱",
  "Europe/Prague": "🇨🇿",
  "Europe/Athens": "🇬🇷",
  "Europe/Istanbul": "🇹🇷",
  "Europe/Moscow": "🇷🇺",

  // Americas
  "America/New_York": "🇺🇸",
  "America/Los_Angeles": "🇺🇸",
  "America/Chicago": "🇺🇸",
  "America/Denver": "🇺🇸",
  "America/Phoenix": "🇺🇸",
  "America/Anchorage": "🐻",
  "America/Toronto": "🇨🇦",
  "America/Vancouver": "🇨🇦",
  "America/Sao_Paulo": "🇧🇷",
  "America/Buenos_Aires": "🇦🇷",
  "America/Bogota": "🇨🇴",
  "America/Lima": "🇵🇪",
  "America/Santiago": "🇨🇱",
  "America/Havana": "🇨🇺",

  // Africa
  "Africa/Cairo": "🇪🇬",
  "Africa/Johannesburg": "🇿🇦",
  "Africa/Lagos": "🇳🇬",
  "Africa/Nairobi": "🇰🇪"
}

var CITY_CODES = {
  // Mexico
  "America/Mexico_City": "MEX",
  "America/Cancun": "CUN",
  "America/Tijuana": "TIJ",
  "America/Monterrey": "MTY",
  "America/Hermosillo": "HMO",
  "America/Mazatlan": "MZT",
  "America/Chihuahua": "CUU",
  "America/Merida": "MID",
  "America/Matamoros": "MAM",
  "America/Bahia_Banderas": "PVR",
  "America/Ciudad_Juarez": "CJS",
  "Mexico/BajaNorte": "TIJ",
  "Mexico/BajaSur": "LAP",
  "Mexico/General": "MEX",

  // Europe
  "Europe/Paris": "PAR",
  "Europe/London": "LON",
  "Europe/Berlin": "BER",
  "Europe/Rome": "ROM",
  "Europe/Madrid": "MAD",
  "Europe/Amsterdam": "AMS",
  "Europe/Brussels": "BRU",
  "Europe/Zurich": "ZRH",
  "Europe/Vienna": "VIE",
  "Europe/Dublin": "DUB",
  "Europe/Lisbon": "LIS",
  "Europe/Stockholm": "STO",
  "Europe/Oslo": "OSL",
  "Europe/Copenhagen": "CPH",
  "Europe/Warsaw": "WAW",
  "Europe/Prague": "PRG",
  "Europe/Athens": "ATH",
  "Europe/Istanbul": "IST",
  "Europe/Moscow": "MOW",

  // Asia & Pacific
  "Asia/Seoul": "SEL",
  "Asia/Tokyo": "TYO",
  "Asia/Shanghai": "SHA",
  "Asia/Hong_Kong": "HKG",
  "Asia/Taipei": "TPE",
  "Asia/Singapore": "SIN",
  "Asia/Bangkok": "BKK",
  "Asia/Jakarta": "JKT",
  "Asia/Dubai": "DXB",
  "Asia/Kolkata": "DEL",
  "Asia/Calcutta": "CCU",
  "Asia/Jerusalem": "JRS",
  "Asia/Riyadh": "RUH",
  "Australia/Sydney": "SYD",
  "Pacific/Auckland": "AKL",
  "Pacific/Honolulu": "HNL",

  // Americas
  "America/New_York": "NYC",
  "America/Los_Angeles": "LAX",
  "America/Chicago": "CHI",
  "America/Denver": "DEN",
  "America/Phoenix": "PHX",
  "America/Anchorage": "ANC",
  "America/Toronto": "YTO",
  "America/Vancouver": "YVR",
  "America/Sao_Paulo": "SAO",
  "America/Buenos_Aires": "BUE",
  "America/Bogota": "BOG",
  "America/Lima": "LIM",
  "America/Santiago": "SCL",

  // Africa
  "Africa/Cairo": "CAI",
  "Africa/Johannesburg": "JNB",
  "Africa/Lagos": "LOS",
  "Africa/Nairobi": "NBO"
}

function friendlyName(id) {
  var parts = String(id || "").split("/")
  var last = parts[parts.length - 1] || id
  return last.replace(/_/g, " ")
}

function regionName(id) {
  var parts = String(id || "").split("/")
  if (parts.length < 2) return ""
  return parts[0].replace(/_/g, " ")
}

function cityIcon(id) {
  return CITY_ICONS[id] || "🌐"
}

function cityCode(id) {
  if (CITY_CODES[id]) return CITY_CODES[id]
  var name = friendlyName(id)
  var letters = name.replace(/[^a-zA-Z]/g, "")
  if (letters.length >= 3) return letters.substring(0, 3).toUpperCase()
  return name.toUpperCase()
}

function formatUtcOffset(offsetStr) {
  if (!offsetStr || typeof offsetStr !== "string") return ""
  var str = offsetStr.trim()
  if (str.length < 5) return str
  var sign = str.charAt(0)
  var hours = parseInt(str.substring(1, 3), 10)
  var mins = str.substring(3, 5)
  if (mins === "00") {
    return "UTC" + sign + hours
  }
  return "UTC" + sign + hours + ":" + mins
}

function parseTimesLine(line) {
  var parts = String(line || "").split("|")
  if (parts.length < 8) return null
  return {
    id: parts[0],
    time24: parts[1],
    time12: parts[2],
    ampm: parts[3],
    date: parts[4],
    weekday: parts[5],
    utcOffset: parts[6],
    abbr: parts[7]
  }
}

function parseTimesOutput(text) {
  var out = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (line === "") continue
    var parsed = parseTimesLine(line)
    if (parsed) out[parsed.id] = parsed
  }
  return out
}

function toUTCms(dateStr) {
  var p = String(dateStr || "").split("-")
  if (p.length < 3) return NaN
  return Date.UTC(Number(p[0]), Number(p[1]) - 1, Number(p[2]))
}

function dayBadge(zoneDate, localDate) {
  if (!zoneDate || !localDate || zoneDate === localDate) return ""
  var diff = Math.round((toUTCms(zoneDate) - toUTCms(localDate)) / 86400000)
  if (diff === 1) return "+1"
  if (diff === -1) return "−1"
  return ""
}

function formatOffset(minutes) {
  var m = Math.round(Number(minutes) || 0)
  if (m === 0) return "Now"
  var sign = m > 0 ? "+" : "−"
  var abs = Math.abs(m)
  var h = Math.floor(abs / 60)
  var mm = abs % 60
  var out = sign
  if (h > 0) out += h + "h"
  if (mm > 0) out += (h > 0 ? " " : "") + mm + "m"
  return out
}
