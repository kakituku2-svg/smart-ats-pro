# WILD CATCH — Production Art Drop-in Contract v0.5.0

このフォルダは仮プリミティブ/プレビューCGから本番CGへ差し替えるための正式な受け口です。ゲームロジック・当たり判定・AI・セーブを変更せず、GLBを所定パスへ置くだけで自動認識する設計です。\n\nFIELD BASE本番環境の配置先: `art/environment/hub/field_base_set.glb`

## 1. Ren

配置先:

`art/characters/ren/ren.glb`

基準:
- 原点: 足元中央 `(0,0,0)`
- 正面: Godotの `-Z`
- 1 Godot unit = 1m
- ゲーム上の身長目安: 1.45〜1.60m相当
- シルエット: 3.5〜4頭身のオリジナル少年冒険家
- Skinned Mesh + Skeleton必須
- 関節球露出禁止
- 髪は360度から破綻しないHair Cap + 前/横/後/上の束構成
- HEX NET / バッグ / Wrist Deviceは必要なら別BoneまたはSocket化
- 走行中の髪・バッグ・布にFollow Throughを入れる

最低AnimationPlayerクリップ名:
- `Idle`
- `Run`
- `Dash`
- `Jump`
- `Fall`
- `Net_1`
- `Net_2`
- `Net_3`
- `Scan`

後続本番クリップ:
- `Land`
- `Gadget_Lure`
- `Gadget_Pulse`
- `Gadget_Drone`
- `Hit`
- `Knockout`
- `CaptureSuccess`
- `TransferIn`
- `TransferOut`

## 2. Mimo — 18体

各個体は次の規則で自動認識します。

`art/mimo/<id>/<id>.glb`

Stage 1:
- `lumi`, `goro`, `boka`, `nera`, `moku`, `raku`

Stage 2:
- `aero`, `kuru`, `vivi`, `toto`, `nagi`

Stage 3:
- `pico`, `luna`, `doro`, `nix`, `fufu`, `zari`, `ema`

共通基準:
- 原点: 足元中央
- 正面: `-Z`
- 2.3〜2.8頭身程度の丸みあるオリジナル生物
- 既存作品の猿・装備・顔・色配置をコピーしない
- 共通骨格は可。ただし耳、頭、胴、腕脚、尻尾、装飾、表情、重心でシルエットを分ける
- 遠距離でも輪郭だけで個体識別できること
- 顔は正面専用でなく、斜め/背面から見ても破綻しないこと

最低AnimationPlayerクリップ名:
- `Idle`
- `Alert`
- `Run`
- `Tired`
- `Recover`
- `Capture`

Stage 1固有候補:
- Lumi: `HideGrass`
- Goro: `ThrowRock`
- Boka: `ChargeTell`, `Charge`
- Nera: `ShockTell`, `Shock`
- Moku: `Sleep`, `DrowsyField`
- Raku: `Feint`, `Decoy`

Stage 2/3は `MissionSignatureRuntime` が既存の意味アニメへ安全にフォールバックします。本番モデルでは個体専用クリップへ段階的に置換します。

## 3. Stage 1 — Tropical Ruins Park

配置先:

`art/environment/stage1/stage1_set.glb`

本番GLBは原則「見た目専用」です。Godot側のCollision、Mimo経路、チェックポイント、遺物、ガジェットギミックは維持します。

必須ランドマーク:
- 木もれび広場
- 石ころ渓谷
- 古代ゲート遺跡
- 観測台跡
- 風見の森
- 水路遺跡
- 隠し祭壇

美術目標:
- 明るい現代3Dアニメ調
- 暖色太陽光 + 青緑環境光
- 草/苔/砂/石/水の素材差
- 遠景/中景/近景を明確に分ける
- 逃走ルートは自然な構図で誘導し、露骨な矢印にしない

## 4. Stage 2 — Skywind Canyon

配置先:

`art/environment/stage2/stage2_skywind.glb`

必須ビジュアル:
- 大きな断崖と高度差
- 風橋/ロープ橋
- 風車設備
- 係留柱、風向旗、整備クレート
- 上昇気流の発生地点が地形/植物/布の動きから読めること
- 遠景に複数層の峡谷を置き、空だけの平面背景にしない

`MissionEnvironmentArtRuntime` がGLBを検出すると、仮の箱地形/小物Visualを隠して本番CGを表示します。Collision、上昇気流、Mimo、妨害敵、チェックポイントはGodot側を維持します。

## 5. Stage 3 — Neon Swamp Research Zone

配置先:

`art/environment/stage3/stage3_neon_swamp.glb`

必須ビジュアル:
- 夜光植物に侵食された旧研究施設
- 研究デッキ、西/東研究棟、高架路
- タンク、配管、観測端末、警告灯
- 水/泥/金属/植物の素材差
- 発光泥沼は危険地形だと自然に読めること
- 紫/青緑/ピンク発光を使いつつ黒潰れを避ける

本番GLBへ差し替えてもGlow Mud、Mimo AI、妨害敵、チェックポイントなどのゲームロジックは残します。

## 6. Field Base

本拠地はステージ選択メニューではなくプレイヤーが歩ける3D空間です。

重要要素:
- 中央転送リング
- Mission Terminal
- 18体分 Capture Archive
- FIELD RECORD端末
- 3ステージのホログラム表示
- 整備/研究設備

将来の本番CGでは「帰還する意味」が視覚的に伝わるよう、捕獲済みスロットや戦績表示の発光状態を残してください。

## 7. Interference Enemies

捕獲対象Mimoとは別系統です。捕獲ネットでは確保できません。

- Guard Bug: 基本追尾/体当たり型
- Wind Stinger: 高速軽量型
- Glow Leech: 近距離スロー妨害型

本番CGでもMimoと輪郭/材質言語を明確に分け、敵だと瞬時に分かること。

## 8. Mobile Performance Budget

Android中級端末を基準に、60fpsを目標、30fpsを最低ラインとします。正式値は `art/performance_budget.json` を正本とします。

現行ソフト上限:
- Ren: 35k triangles程度以下を目標 / Texture最大2K
- Mimo: 20k triangles以下 / 1体 / Texture最大1K
- Stage表示中: 約180k visible trianglesをソフト上限
- Draw Call: 120以下を目標
- 小物の反復はMultiMesh/共有Materialを優先
- 小型Decorは原則Shadow OFF
- Androidでは遠距離Decorを積極的にカリング
- 4K Texture、多数の透明材質、個別Dynamic Light乱立を避ける
- PBRはORM統合を優先

## 9. Import QA

本番GLBを置いた後のCIで必ず確認する:
1. Godot import成功
2. Main scene起動
3. ProductionArt/ProductionEnvironmentArt自動認識
4. AnimationPlayer必須クリップ検出
5. 該当する仮Visualだけが非表示になる
6. Collision / SCAN / Capture / AI / Hazardは従来通り動く
7. Android APK export成功
8. 正面/背面/走行/捕獲/固有技/ステージ全景をVisual QAで目視
9. Android実機でFPS/メモリ/発熱を計測

本番アセットがまだ無い場合は、現在のプレビューCG + procedural animation + runtime environmentへ自動フォールバックします。
