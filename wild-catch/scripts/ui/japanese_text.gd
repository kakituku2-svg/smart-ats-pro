extends RefCounted
class_name JapaneseText

static func mimo_name(mimo_id: Variant, fallback: String = "ミモ") -> String:
    match String(mimo_id):
        "lumi": return "ルミ"
        "goro": return "ゴロ"
        "boka": return "ボカ"
        "nera": return "ネラ"
        "moku": return "モク"
        "raku": return "ラク"
        "aero": return "アエロ"
        "kuru": return "クル"
        "vivi": return "ビビ"
        "toto": return "トト"
        "nagi": return "ナギ"
        "pico": return "ピコ"
        "luna": return "ルナ"
        "doro": return "ドロ"
        "nix": return "ニクス"
        "fufu": return "フフ"
        "zari": return "ザリ"
        "ema": return "エマ"
    return fallback

static func behavior(value: Variant) -> String:
    match String(value):
        "timid": return "臆病・草むら逃走型"
        "zigzag": return "ジグザグ逃走型"
        "challenger": return "挑発・切り返し型"
        "sentinel": return "高警戒・加速型"
        "sleepy": return "のんびり・鈍足型"
        "trickster": return "トリックスター型"
        "runner": return "逃走型"
    return String(value)

static func state(value: Variant) -> String:
    match String(value):
        "ROUTINE": return "通常"
        "ALERT": return "警戒"
        "PANIC": return "逃走中"
        "FATIGUED": return "疲労"
        "RECOVER": return "回復中"
        "CAPTURED": return "捕獲済み"
    return String(value)

static func direction(value: Variant) -> String:
    match String(value):
        "N": return "北"
        "E": return "東"
        "S": return "南"
        "W": return "西"
    return String(value)

static func route(value: Variant) -> String:
    match String(value):
        "dynamic": return "状況に応じて変化"
        "grass": return "草地"
        "brush": return "茂み"
        "clearing": return "木もれび広場"
        "ravine": return "石ころ渓谷"
        "rock_loop": return "岩場周回"
        "open_turn": return "開けた切り返し"
        "gate": return "古代ゲート"
        "terrace": return "遺跡テラス"
        "ruins": return "遺跡内部"
        "upper_terrace": return "上層テラス"
        "watch_point": return "観測台跡"
        "ramp": return "坂道"
        "forest_ledge": return "森の高台"
        "deep_forest": return "風見の森・奥"
        "moss_path": return "苔むした小道"
        "water_steps": return "水路の飛び石"
        "water_bridge": return "水路橋"
        "far_bank": return "対岸"
    return String(value).replace("_", " ")

static func capture_status(value: Variant) -> String:
    var raw := String(value)
    match raw:
        "READY — HEX NET NOW": return "捕獲チャンス！ 今すぐ捕獲ネット"
        "STUNNED — CLOSE IN": return "スタン中・今のうちに接近"
        "LURED — SET UP AN AMBUSH": return "誘導中・待ち伏せのチャンス"
        "NEARLY TIRED": return "もうすぐ疲労"
        "CHASE": return "追跡中"
        "ALERT": return "警戒中"
        "TRACK": return "追跡可能"
    if raw.contains("READY"):
        return "捕獲チャンス"
    return raw

static func area(mimo_id: Variant, fallback: String = "不明エリア") -> String:
    match String(mimo_id):
        "lumi": return "木もれび広場"
        "goro": return "石ころ渓谷"
        "boka": return "古代ゲート遺跡"
        "nera": return "観測台跡"
        "moku": return "風見の森"
        "raku": return "水路遺跡"
    return fallback

static func personality(mimo_id: Variant, fallback: String = "") -> String:
    match String(mimo_id):
        "lumi": return "臆病で慎重"
        "goro": return "せっかちで石好き"
        "boka": return "勝負好き"
        "nera": return "警戒心が強い"
        "moku": return "眠たがり"
        "raku": return "いたずら好き"
    return fallback

static func hint(mimo_id: Variant, fallback: String = "") -> String:
    match String(mimo_id):
        "lumi": return "誘導ポッドで草むらから広場へ出すと捕まえやすい"
        "goro": return "パルスでジグザグ逃走を止めて距離を詰める"
        "boka": return "狭い遺跡から開けた場所へ誘い出して2段目ネット"
        "nera": return "ドローンで高台の本体を見失わず、加速の切れ目を狙う"
        "moku": return "完全に起きる前は誘導ポッドの効きが強い"
        "raku": return "ドローンで本物だけを短時間マーキングし、分身を無視する"
    return fallback

static func relic_name(relic_id: Variant) -> String:
    match String(relic_id):
        "sun_disc": return "太陽の円盤"
        "gate_tablet": return "門の石板"
        "river_pearl": return "水路の真珠"
        "watch_eye": return "観測者の瞳"
        "moss_seal": return "苔の封印"
        "far_bank_coin": return "対岸の古銭"
    return String(relic_id)
