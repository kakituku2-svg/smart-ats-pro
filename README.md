# Smart ATS Pro v0.5.0

Smart ATS / SmartHire の構想をAndroid APK向けに再構築した、ローカルファーストの採用管理ATSです。

## 特徴
- ログインなしでローカル利用可能
- 候補者 / 求人 / 選考 / 面接 / 履歴管理
- Gemini APIを任意設定して、PDF / PNG / JPEGの履歴書・職務経歴書解析
- AI職務要約 / スカウト文 / メール返信 / 面接質問
- Gemini APIキーはAndroid Keystore + AES-GCMで保護
- 履歴書・職務経歴書の原本保存は任意。保存時は端末内で暗号化
- Supabase / Gmail連携は任意。未設定でも利用可能
- AIによる自動合否・自動メール送信は行わない

## Android
- applicationId: `jp.smartats.pro`
- versionName: `0.5.0`
- versionCode: `5`
- compileSdk / targetSdk: 35

## APK
GitHub Actionsで `SmartATSPro-v0.5.0-debug.apk` を生成する構成です。公開リポジトリでは標準GitHub-hosted runnerを使ってビルド可否を確認します。

## セキュリティ
実APIキー、署名鍵、履歴書実データ、候補者の実個人情報はこの公開リポジトリへコミットしないでください。Gemini APIキーはAPK起動後に各ユーザーが設定する方式です。
