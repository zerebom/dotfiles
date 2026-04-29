#!/usr/bin/env python3
"""
Gemini API を使用した画像生成スクリプト

使用例:
    # Text-to-Image
    python generate.py --prompt "モダンなロゴ" --output ./logo.png

    # Image-to-Image（編集）
    python generate.py --prompt "背景を変更" --input ./original.png --output ./edited.png
"""

import argparse
import base64
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


# 定数
API_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent"
VALID_ASPECT_RATIOS = ["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"]
VALID_SIZES = ["1K", "2K", "4K"]
DEFAULT_OUTPUT_DIR = "generated_images"


def get_default_output_path() -> str:
    """デフォルトの出力パスを生成（タイムスタンプ付き）"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = Path(DEFAULT_OUTPUT_DIR)
    output_dir.mkdir(parents=True, exist_ok=True)
    return str(output_dir / f"{timestamp}.png")


def get_api_key(args_api_key: str | None) -> str:
    """APIキーを取得（引数 > 環境変数の優先順位）"""
    if args_api_key:
        return args_api_key
    
    env_key = os.environ.get("GEMINI_API_KEY")
    if env_key:
        return env_key
    
    print("エラー: APIキーが設定されていません。", file=sys.stderr)
    print("  --api-key オプションで指定するか、環境変数 GEMINI_API_KEY を設定してください。", file=sys.stderr)
    sys.exit(1)


def load_image_as_base64(image_path: str) -> tuple[str, str]:
    """画像ファイルをBase64エンコードして返す"""
    path = Path(image_path)
    if not path.exists():
        print(f"エラー: 入力画像が見つかりません: {image_path}", file=sys.stderr)
        sys.exit(1)
    
    # MIMEタイプを拡張子から判定
    ext = path.suffix.lower()
    mime_types = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".gif": "image/gif",
        ".webp": "image/webp",
    }
    mime_type = mime_types.get(ext, "image/png")
    
    with open(path, "rb") as f:
        data = base64.b64encode(f.read()).decode("utf-8")
    
    return data, mime_type


def build_request_body(
    prompt: str,
    input_image: str | None,
    aspect_ratio: str,
    size: str,
) -> dict:
    """APIリクエストボディを構築"""
    parts = []
    
    # 入力画像がある場合（Image-to-Image）
    if input_image:
        image_data, mime_type = load_image_as_base64(input_image)
        parts.append({
            "inline_data": {
                "mime_type": mime_type,
                "data": image_data,
            }
        })
    
    # プロンプト
    parts.append({"text": prompt})
    
    return {
        "contents": [{
            "parts": parts
        }],
        "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"],
            "imageConfig": {
                "aspectRatio": aspect_ratio,
                "imageSize": size,
            }
        }
    }


def call_api(api_key: str, request_body: dict) -> dict:
    """Gemini APIを呼び出す"""
    url = f"{API_ENDPOINT}?key={api_key}"
    
    headers = {
        "Content-Type": "application/json",
    }
    
    data = json.dumps(request_body).encode("utf-8")
    request = Request(url, data=data, headers=headers, method="POST")
    
    try:
        with urlopen(request, timeout=120) as response:
            return json.loads(response.read().decode("utf-8"))
    except HTTPError as e:
        error_body = e.read().decode("utf-8")
        print(f"APIエラー ({e.code}): {error_body}", file=sys.stderr)
        sys.exit(1)
    except URLError as e:
        print(f"接続エラー: {e.reason}", file=sys.stderr)
        sys.exit(1)
    except TimeoutError:
        print("エラー: APIリクエストがタイムアウトしました", file=sys.stderr)
        sys.exit(1)


def extract_and_save_image(response: dict, output_path: str) -> bool:
    """レスポンスから画像を抽出して保存"""
    try:
        candidates = response.get("candidates", [])
        if not candidates:
            print("エラー: レスポンスに候補がありません", file=sys.stderr)
            return False
        
        parts = candidates[0].get("content", {}).get("parts", [])
        
        for part in parts:
            # テキスト部分があれば出力
            if "text" in part:
                text = part["text"]
                if text.strip():
                    print(f"モデルからのメッセージ: {text}")
            
            # 画像データを探す
            if "inlineData" in part:
                image_data = part["inlineData"].get("data")
                if image_data:
                    # Base64デコードして保存
                    image_bytes = base64.b64decode(image_data)
                    
                    # 出力ディレクトリがなければ作成
                    output_file = Path(output_path)
                    output_file.parent.mkdir(parents=True, exist_ok=True)
                    
                    with open(output_file, "wb") as f:
                        f.write(image_bytes)
                    
                    print(f"画像を保存しました: {output_path}")
                    return True
        
        print("エラー: レスポンスに画像データが含まれていません", file=sys.stderr)
        return False
        
    except Exception as e:
        print(f"エラー: 画像の保存に失敗しました: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Gemini APIを使用して画像を生成・編集します",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用例:
  # テキストから画像生成
  python generate.py --prompt "モダンなコーヒーショップのロゴ" --output ./logo.png

  # 画像編集
  python generate.py --prompt "背景を夕焼けに変更" --input ./photo.png --output ./edited.png

  # オプション指定
  python generate.py --prompt "都市の風景" --output ./city.png --aspect-ratio 16:9 --size 2K
        """
    )
    
    parser.add_argument(
        "--prompt", "-p",
        required=True,
        help="画像の説明または編集指示"
    )
    parser.add_argument(
        "--output", "-o",
        default=None,
        help="出力ファイルパス（省略時: ./generated_images/{timestamp}.png）"
    )
    parser.add_argument(
        "--input", "-i",
        help="入力画像パス（画像編集時に使用）"
    )
    parser.add_argument(
        "--aspect-ratio", "-a",
        default="1:1",
        choices=VALID_ASPECT_RATIOS,
        help=f"アスペクト比（デフォルト: 1:1）"
    )
    parser.add_argument(
        "--size", "-s",
        default="1K",
        choices=VALID_SIZES,
        help="解像度（デフォルト: 1K）"
    )
    parser.add_argument(
        "--api-key", "-k",
        help="Gemini APIキー（未指定時は環境変数 GEMINI_API_KEY を使用）"
    )
    
    args = parser.parse_args()

    # APIキー取得
    api_key = get_api_key(args.api_key)

    # 出力パスが指定されていない場合はデフォルトを使用
    output_path = args.output if args.output else get_default_output_path()
    
    # リクエストボディ構築
    print(f"画像を生成中...")
    if args.input:
        print(f"  入力画像: {args.input}")
    print(f"  プロンプト: {args.prompt}")
    print(f"  アスペクト比: {args.aspect_ratio}")
    print(f"  解像度: {args.size}")
    
    request_body = build_request_body(
        prompt=args.prompt,
        input_image=args.input,
        aspect_ratio=args.aspect_ratio,
        size=args.size,
    )
    
    # API呼び出し
    response = call_api(api_key, request_body)

    # 画像を抽出して保存
    success = extract_and_save_image(response, output_path)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
